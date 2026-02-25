/**
 * af_detection_v5.h
 * AF Detection System v5.0
 * Ashesi University Capstone Project
 *
 * CLASSIFIER SUMMARY:
 *   Algorithm    : Random Forest (7 trees, max_depth=4)
 *   Training data: MIT-BIH AF Database (PhysioNet), 47,690 windows
 *   Accuracy     : 82.50%
 *   Sensitivity  : 87.93%
 *   Specificity  : 78.53%
 *   File size    : 25.6 KB
 *
 *   Configuration selected by grid search over tree count
 *   (5,7,10,15,20) and depth (2,3,4). 7 trees depth 4
 *   achieved best accuracy under 30KB compiler limit with
 *   6/6 correct on held-out validation cases.
 *
 * FEATURES (7) ranked by F-statistic, Table 2:
 *   RR Interval-based AF Detection using Traditional
 *   and Ensemble Machine Learning Algorithms
 *
 *   x[0] mean_rr  Rank 9  (F=8.02)
 *   x[1] pRR20    Rank 1  (F=21.21)
 *   x[2] pRR6_25  Rank 2  (F=17.95)
 *   x[3] pRR30    Rank 4  (F=15.08)
 *   x[4] pRR50    Rank 7  (F=9.12)
 *   x[5] sdsd     Rank 10 (F=5.38)
 *   x[6] tpr      Dash et al. (2009)
 *
 * VALIDATION:
 *   Full RF (100 trees): Accuracy=85.43%, Se=92.70%, AUC=0.9256
 *   ESP32 RF (7 trees) : Accuracy=82.50%, Se=87.93%, Size=25.6KB
 *   Manual validation  : 6/6 correct on held-out test cases
 *
 * REFERENCES:
 *   [1] Dash et al. Ann Biomed Eng. 2009;37(9):1701-1709.
 *   [2] Shrikanth Rao & Martis. J Med Signals Sens. 2023;13(3):224-232.
 *   [3] Task Force ESC/NASPE. Circulation. 1996;93(5):1043-1065.
 *   [4] MIT-BIH AF Database. PhysioNet.
 *   [5] Pan & Tompkins. IEEE TBME. 1985;32(3):230-236.
 */

#ifndef AF_DETECTION_V5_H
#define AF_DETECTION_V5_H

#include <Arduino.h>
#include <math.h>

// ── CONFIGURATION ──────────────────────────────────────────
#define RR_BUFFER_SIZE     30
#define MIN_VALID_RR       300
#define MAX_VALID_RR       2000

// ── TPR COMPUTATION (Dash et al. 2009) ────────────────────
// Tests for randomness in RR interval sequence
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

// ── RANDOM FOREST (micromlgen) ─────────────────────────────
#pragma once
#include <cstdarg>
namespace Eloquent {
    namespace ML {
        namespace Port {
            class RandomForest {
                public:
                    /**
                    * Predict class for features vector
                    */
                    int predict(float *x) {
                        uint8_t votes[2] = { 0 };
                        // tree #1
                        if (x[4] <= 17.316341400146484) {
                            if (x[2] <= 98.27586364746094) {
                                if (x[1] <= 49.13793182373047) {
                                    if (x[6] <= -2.049557328224182) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }

                                else {
                                    if (x[0] <= 481.61158752441406) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }
                            }

                            else {
                                if (x[0] <= 459.3777770996094) {
                                    if (x[4] <= 13.961039066314697) {
                                        votes[1] += 1;
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
                            if (x[5] <= 70.03127670288086) {
                                if (x[1] <= 62.28448295593262) {
                                    if (x[0] <= 498.06666564941406) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }

                                else {
                                    if (x[0] <= 817.6666564941406) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }
                            }

                            else {
                                if (x[0] <= 455.56471252441406) {
                                    if (x[6] <= -2.2149258852005005) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[1] += 1;
                                    }
                                }

                                else {
                                    if (x[2] <= 89.82758712768555) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }
                            }
                        }

                        // tree #2
                        if (x[1] <= 49.13793182373047) {
                            if (x[5] <= 48.88909149169922) {
                                if (x[3] <= 24.568965911865234) {
                                    if (x[2] <= 93.21839141845703) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }

                                else {
                                    if (x[0] <= 468.54022216796875) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }
                            }

                            else {
                                if (x[0] <= 395.2666778564453) {
                                    if (x[2] <= 90.45454406738281) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[1] += 1;
                                    }
                                }

                                else {
                                    if (x[1] <= 38.01313591003418) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }
                            }
                        }

                        else {
                            if (x[5] <= 74.33849334716797) {
                                if (x[0] <= 761.9333190917969) {
                                    if (x[4] <= 24.568965911865234) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[1] += 1;
                                    }
                                }

                                else {
                                    if (x[1] <= 84.48275756835938) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[1] += 1;
                                    }
                                }
                            }

                            else {
                                if (x[0] <= 469.42298889160156) {
                                    if (x[4] <= 58.85579872131348) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[1] += 1;
                                    }
                                }

                                else {
                                    if (x[3] <= 72.5705337524414) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }
                            }
                        }

                        // tree #3
                        if (x[4] <= 24.568965911865234) {
                            if (x[3] <= 31.14224147796631) {
                                if (x[2] <= 98.27586364746094) {
                                    if (x[3] <= 17.51918125152588) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }

                                else {
                                    if (x[0] <= 458.93333435058594) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }
                            }

                            else {
                                if (x[5] <= 49.88425254821777) {
                                    if (x[0] <= 498.0) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }

                                else {
                                    if (x[1] <= 72.5705337524414) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[1] += 1;
                                    }
                                }
                            }
                        }

                        else {
                            if (x[3] <= 49.13793182373047) {
                                if (x[3] <= 48.212005615234375) {
                                    if (x[1] <= 49.13793182373047) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[1] += 1;
                                    }
                                }

                                else {
                                    if (x[2] <= 84.48275756835938) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }
                            }

                            else {
                                if (x[0] <= 761.5333251953125) {
                                    if (x[3] <= 62.28448295593262) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[1] += 1;
                                    }
                                }

                                else {
                                    if (x[2] <= 96.49015045166016) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }
                            }
                        }

                        // tree #4
                        if (x[1] <= 49.13793182373047) {
                            if (x[3] <= 24.568965911865234) {
                                if (x[3] <= 14.039408683776855) {
                                    if (x[5] <= 3.0241881608963013) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }

                                else {
                                    if (x[0] <= 450.81158447265625) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }
                            }

                            else {
                                if (x[0] <= 418.85057067871094) {
                                    if (x[6] <= -3.9845465421676636) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[1] += 1;
                                    }
                                }

                                else {
                                    if (x[6] <= -4.45419454574585) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }
                            }
                        }

                        else {
                            if (x[0] <= 737.5333251953125) {
                                if (x[5] <= 73.24560928344727) {
                                    if (x[1] <= 66.09195327758789) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[1] += 1;
                                    }
                                }

                                else {
                                    if (x[1] <= 66.09195327758789) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }
                            }

                            else {
                                if (x[4] <= 65.36731719970703) {
                                    if (x[4] <= 44.41379356384277) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }

                                else {
                                    if (x[3] <= 77.58620834350586) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[1] += 1;
                                    }
                                }
                            }
                        }

                        // tree #5
                        if (x[1] <= 49.13793182373047) {
                            if (x[2] <= 98.27586364746094) {
                                if (x[1] <= 38.01313591003418) {
                                    if (x[4] <= 10.435571670532227) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }

                                else {
                                    if (x[1] <= 41.27789115905762) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }
                            }

                            else {
                                if (x[0] <= 536.7267150878906) {
                                    if (x[1] <= 23.61111068725586) {
                                        votes[1] += 1;
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
                            if (x[5] <= 72.23062133789062) {
                                if (x[4] <= 24.568965911865234) {
                                    if (x[0] <= 498.0) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }

                                else {
                                    if (x[1] <= 66.09195327758789) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[1] += 1;
                                    }
                                }
                            }

                            else {
                                if (x[1] <= 72.5705337524414) {
                                    if (x[0] <= 454.75999450683594) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }

                                else {
                                    if (x[5] <= 94.74857330322266) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }
                            }
                        }

                        // tree #6
                        if (x[0] <= 543.3999938964844) {
                            if (x[2] <= 83.04597854614258) {
                                if (x[0] <= 423.93333435058594) {
                                    if (x[3] <= 18.8988094329834) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[1] += 1;
                                    }
                                }

                                else {
                                    if (x[4] <= 32.738094329833984) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }
                            }

                            else {
                                if (x[6] <= 1.9356340169906616) {
                                    if (x[5] <= 59.069313049316406) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[1] += 1;
                                    }
                                }

                                else {
                                    if (x[6] <= 2.8101123571395874) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }
                            }
                        }

                        else {
                            if (x[3] <= 64.49579620361328) {
                                if (x[3] <= 51.787994384765625) {
                                    if (x[5] <= 27.633061408996582) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }

                                else {
                                    if (x[5] <= 68.58501434326172) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }
                            }

                            else {
                                if (x[4] <= 78.78561019897461) {
                                    if (x[5] <= 70.44427108764648) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }

                                else {
                                    if (x[0] <= 699.5333251953125) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[1] += 1;
                                    }
                                }
                            }
                        }

                        // tree #7
                        if (x[1] <= 49.13793182373047) {
                            if (x[4] <= 14.039408683776855) {
                                if (x[6] <= -2.02321720123291) {
                                    if (x[0] <= 418.7246398925781) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }

                                else {
                                    if (x[0] <= 422.98333740234375) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }
                            }

                            else {
                                if (x[0] <= 407.30223083496094) {
                                    if (x[0] <= 382.79998779296875) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[1] += 1;
                                    }
                                }

                                else {
                                    if (x[2] <= 98.27586364746094) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[1] += 1;
                                    }
                                }
                            }
                        }

                        else {
                            if (x[1] <= 66.09195327758789) {
                                if (x[0] <= 491.92857360839844) {
                                    if (x[2] <= 98.27586364746094) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[1] += 1;
                                    }
                                }

                                else {
                                    if (x[1] <= 58.72210884094238) {
                                        votes[0] += 1;
                                    }

                                    else {
                                        votes[0] += 1;
                                    }
                                }
                            }

                            else {
                                if (x[1] <= 76.69683456420898) {
                                    if (x[1] <= 67.26190185546875) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[1] += 1;
                                    }
                                }

                                else {
                                    if (x[2] <= 98.27586364746094) {
                                        votes[1] += 1;
                                    }

                                    else {
                                        votes[1] += 1;
                                    }
                                }
                            }
                        }

                        // return argmax of votes
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
                            case 0:
                            return "NORMAL";
                            case 1:
                            return "AF";
                            default:
                            return "Houston we have a problem";
                        }
                    }

                protected:
                };
            }
        }
    }
#endif // AF_DETECTION_V5_H
