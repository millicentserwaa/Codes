/**
 * af_detection_esp32.h
 * AF Detection Classifier — ESP32 Deployment
 * Ashesi University Capstone Project
 *
 * Generated from MIT-BIH AF Database (PhysioNet)
 * Model: Random Forest (3 trees, max depth 5)
 * Features: mean_rr, pRR20, pRR6_25, pRR30, pRR50, sdsd, tpr
 *
 * Performance on held-out test set (9,538 windows):
 *   Accuracy    : 82.48%
 *   Sensitivity : 89.65%
 *   Specificity : 77.24%
 *   AUC-ROC     : 0.8951
 *   10-fold CV  : 81.98% ± 0.45%
 *
 * Configuration selected by grid search (trees: 3,5,7,10 | depth: 3,4,5,6)
 * 3 trees depth 5 = highest sensitivity within 30KB flash limit.
 * Sensitivity prioritised over accuracy for screening application.
 *
 * Feature order for predict() / predictWithVotes():
 *   x[0] = mean_rr   (ms)
 *   x[1] = pRR20     (%)
 *   x[2] = pRR6_25   (%)
 *   x[3] = pRR30     (%)
 *   x[4] = pRR50     (%)
 *   x[5] = sdsd      (ms)
 *   x[6] = tpr       (z-score)
 *
 * predictWithVotes() usage:
 *   uint8_t votes[2] = {0};
 *   int prediction = clf.predictWithVotes(features, votes);
 *   int confidence = (int)((float)votes[prediction] / 3.0f * 100.0f);
 *
 *   votes[0] = trees voting NORMAL (out of 3)
 *   votes[1] = trees voting AF     (out of 3)
 *   3/3 AF votes → confidence 100% (unanimous)
 *   2/3 AF votes → confidence  67% (majority)
 *
 * References:
 *   [1] Dash et al. Ann Biomed Eng. 2009;37(9):1701-1709.
 *   [2] MIT-BIH AF Database. PhysioNet. doi:10.13026/C2MW2D
 *   [3] Task Force ESC/NASPE. Circulation. 1996;93(5):1043-1065.
 */

#ifndef AF_DETECTION_ESP32_H
#define AF_DETECTION_ESP32_H

#include <Arduino.h>
#include <math.h>

// ── CONFIGURATION ─────────────────────────────────────────
#define RR_BUFFER_SIZE     30
#define MIN_VALID_RR       300
#define MAX_VALID_RR       2000

// ── TPR COMPUTATION (Dash et al. 2009) ───────────────────
// Tests for randomness in RR interval sequence.
// AF: near 0 (random) | Normal: negative (periodic)
float compute_tpr(float* rr, int n) {
    if (n < 5) return 0.0f;
    int tp = 0;
    for (int i = 1; i < n - 1; i++) {
        if ((rr[i] > rr[i-1] && rr[i] > rr[i+1]) ||
            (rr[i] < rr[i-1] && rr[i] < rr[i+1])) tp++;
    }
    float expected_tp = (2.0f * n - 4.0f) / 3.0f;
    float expected_sd = sqrtf((16.0f * n - 29.0f) / 90.0f);
    if (expected_sd < 1e-6f) return 0.0f;
    return (tp - expected_tp) / expected_sd;
}

// ── RANDOM FOREST (micromlgen) ────────────────────────────
#pragma once
#include <cstdarg>
namespace Eloquent {
    namespace ML {
        namespace Port {
            class RandomForest {
                public:

                    /**
                     * Predict class for features vector.
                     * Returns 0 (NORMAL) or 1 (AF).
                     */
                    int predict(float *x) {
                        uint8_t votes[2] = { 0 };
                        _runTrees(x, votes);

                        uint8_t classIdx = 0;
                        float maxVotes = votes[0];
                        for (uint8_t i = 1; i < 2; i++) {
                            if (votes[i] > maxVotes) {
                                classIdx = i;
                                maxVotes = votes[i];
                            }
                        }
                        return classIdx;
                    }

                    /**
                     * Predict and expose raw vote counts.
                     * Confidence = votes[prediction] / 3 * 100
                     *
                     * Usage:
                     *   uint8_t votes[2] = {0};
                     *   int prediction = clf.predictWithVotes(features, votes);
                     *   int confidence = (int)((float)votes[prediction] / 3.0f * 100.0f);
                     */
                    int predictWithVotes(float *x, uint8_t *votesOut) {
                        uint8_t votes[2] = { 0 };
                        _runTrees(x, votes);

                        votesOut[0] = votes[0];
                        votesOut[1] = votes[1];

                        uint8_t classIdx = 0;
                        float maxVotes = votes[0];
                        for (uint8_t i = 1; i < 2; i++) {
                            if (votes[i] > maxVotes) {
                                classIdx = i;
                                maxVotes = votes[i];
                            }
                        }
                        return classIdx;
                    }

                    /**
                     * Predict readable class name
                     */
                    const char* predictLabel(float *x) {
                        return idxToLabel(predict(x));
                    }

                    /**
                     * Convert class idx to readable name
                     */
                    const char* idxToLabel(uint8_t classIdx) {
                        switch (classIdx) {
                            case 0:  return "NORMAL";
                            case 1:  return "AF";
                            default: return "Houston we have a problem";
                        }
                    }

                protected:

                    /**
                     * Internal: run all 3 trees and fill votes array.
                     * Both predict() and predictWithVotes() call this.
                     *
                     * Trained on MIT-BIH AF Database (PhysioNet)
                     * 47,690 windows | 80/20 split | random_state=42
                     */
                    void _runTrees(float *x, uint8_t *votes) {

                        // ── tree #1 ───────────────────────────────────────
                        if (x[4] <= 17.316341400146484) {
                            if (x[2] <= 98.27586364746094) {
                                if (x[1] <= 49.13793182373047) {
                                    if (x[6] <= -2.049557328224182) {
                                        if (x[0] <= 415.5762939453125) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                    else {
                                        if (x[0] <= 427.2974395751953) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                }
                                else {
                                    if (x[2] <= 85.96059036254883) {
                                        if (x[5] <= 61.413333892822266) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                    else {
                                        if (x[4] <= 16.95402240753174) {
                                            votes[0] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                }
                            }
                            else {
                                if (x[0] <= 459.3777770996094) {
                                    if (x[0] <= 322.76190185546875) {
                                        if (x[0] <= 315.75) {
                                            votes[0] += 1;
                                        }
                                        else {
                                            votes[1] += 1;
                                        }
                                    }
                                    else {
                                        if (x[4] <= 15.58704423904419) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[1] += 1;
                                        }
                                    }
                                }
                                else {
                                    votes[0] += 1;
                                }
                            }
                        }
                        else {
                            if (x[4] <= 34.54907035827637) {
                                if (x[3] <= 44.91379356384277) {
                                    if (x[4] <= 20.34482765197754) {
                                        if (x[1] <= 46.86274528503418) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[1] += 1;
                                        }
                                    }
                                    else {
                                        if (x[4] <= 20.761494636535645) {
                                            votes[0] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                }
                                else {
                                    if (x[4] <= 33.90804481506348) {
                                        if (x[2] <= 98.27586364746094) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[1] += 1;
                                        }
                                    }
                                    else {
                                        if (x[5] <= 56.40364074707031) {
                                            votes[0] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                }
                            }
                            else {
                                if (x[5] <= 70.03127670288086) {
                                    if (x[4] <= 75.43103408813477) {
                                        if (x[6] <= 1.9322317242622375) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                    else {
                                        if (x[6] <= 2.605852246284485) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                }
                                else {
                                    if (x[0] <= 514.3250122070312) {
                                        if (x[1] <= 66.09195327758789) {
                                            votes[0] += 1;
                                        }
                                        else {
                                            votes[1] += 1;
                                        }
                                    }
                                    else {
                                        if (x[1] <= 76.0952377319336) {
                                            votes[0] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                }
                            }
                        }

                        // ── tree #2 ───────────────────────────────────────
                        if (x[1] <= 49.13793182373047) {
                            if (x[5] <= 48.88909149169922) {
                                if (x[3] <= 24.568965911865234) {
                                    if (x[2] <= 93.21839141845703) {
                                        if (x[0] <= 436.8047637939453) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                    else {
                                        if (x[0] <= 436.5416717529297) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                }
                                else {
                                    if (x[0] <= 468.54022216796875) {
                                        if (x[4] <= 9.7619047164917) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[1] += 1;
                                        }
                                    }
                                    else {
                                        if (x[5] <= 24.736217498779297) {
                                            votes[0] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                }
                            }
                            else {
                                if (x[0] <= 395.2666778564453) {
                                    if (x[3] <= 21.98067569732666) {
                                        if (x[2] <= 85.44973754882812) {
                                            votes[0] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                    else {
                                        if (x[0] <= 360.43182373046875) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                }
                                else {
                                    if (x[3] <= 38.01313591003418) {
                                        if (x[3] <= 24.568965911865234) {
                                            votes[0] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                    else {
                                        if (x[0] <= 496.94544982910156) {
                                            votes[0] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                }
                            }
                        }
                        else {
                            if (x[0] <= 742.44140625) {
                                if (x[5] <= 67.70795059204102) {
                                    if (x[4] <= 24.568965911865234) {
                                        if (x[0] <= 498.0) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                    else {
                                        if (x[6] <= 2.364937901496887) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                }
                                else {
                                    if (x[2] <= 93.21839141845703) {
                                        if (x[0] <= 440.4022979736328) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                    else {
                                        if (x[0] <= 534.8808898925781) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                }
                            }
                            else {
                                if (x[0] <= 761.9333190917969) {
                                    if (x[1] <= 74.4694938659668) {
                                        if (x[3] <= 50.86206817626953) {
                                            votes[0] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                    else {
                                        if (x[5] <= 77.54554748535156) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                }
                                else {
                                    if (x[1] <= 84.48275756835938) {
                                        if (x[6] <= -3.8919278383255005) {
                                            votes[0] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                    else {
                                        if (x[3] <= 77.58620834350586) {
                                            votes[0] += 1;
                                        }
                                        else {
                                            votes[1] += 1;
                                        }
                                    }
                                }
                            }
                        }

                        // ── tree #3 ───────────────────────────────────────
                        if (x[4] <= 24.568965911865234) {
                            if (x[3] <= 31.14224147796631) {
                                if (x[2] <= 98.27586364746094) {
                                    if (x[3] <= 17.51918125152588) {
                                        if (x[0] <= 420.1428527832031) {
                                            votes[0] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                    else {
                                        if (x[5] <= 48.88729286193848) {
                                            votes[0] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                }
                                else {
                                    if (x[0] <= 458.93333435058594) {
                                        if (x[1] <= 24.038461685180664) {
                                            votes[0] += 1;
                                        }
                                        else {
                                            votes[1] += 1;
                                        }
                                    }
                                    else {
                                        votes[0] += 1;
                                    }
                                }
                            }
                            else {
                                if (x[4] <= 24.068965911865234) {
                                    if (x[3] <= 41.52298927307129) {
                                        if (x[1] <= 41.042781829833984) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                    else {
                                        if (x[0] <= 496.1476135253906) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                }
                                else {
                                    if (x[5] <= 41.27282524108887) {
                                        if (x[5] <= 40.96064376831055) {
                                            votes[0] += 1;
                                        }
                                        else {
                                            votes[1] += 1;
                                        }
                                    }
                                    else {
                                        if (x[0] <= 438.06666564941406) {
                                            votes[0] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                }
                            }
                        }
                        else {
                            if (x[0] <= 481.5826110839844) {
                                if (x[1] <= 49.13793182373047) {
                                    if (x[1] <= 47.72256851196289) {
                                        if (x[0] <= 425.2222137451172) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                    else {
                                        if (x[0] <= 381.0) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                }
                                else {
                                    if (x[3] <= 69.09814071655273) {
                                        if (x[4] <= 27.42946720123291) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[1] += 1;
                                        }
                                    }
                                    else {
                                        if (x[1] <= 98.27586364746094) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[1] += 1;
                                        }
                                    }
                                }
                            }
                            else {
                                if (x[5] <= 70.57231521606445) {
                                    if (x[1] <= 62.28448295593262) {
                                        if (x[0] <= 546.7333374023438) {
                                            votes[0] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                    else {
                                        if (x[5] <= 32.85220527648926) {
                                            votes[0] += 1;
                                        }
                                        else {
                                            votes[1] += 1;
                                        }
                                    }
                                }
                                else {
                                    if (x[4] <= 58.72210884094238) {
                                        if (x[4] <= 49.13793182373047) {
                                            votes[0] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                    else {
                                        if (x[5] <= 85.00020599365234) {
                                            votes[1] += 1;
                                        }
                                        else {
                                            votes[0] += 1;
                                        }
                                    }
                                }
                            }
                        }

                    } // end _runTrees

            }; // end class RandomForest
        }
    }
}

#endif // AF_DETECTION_ESP32_H