import wfdb

# Lists record names available in this PhysioNet dataset
records = wfdb.get_record_list("bidmc")
print("Number of records:", len(records))
print("First 30 records:")
print(records[:30])
