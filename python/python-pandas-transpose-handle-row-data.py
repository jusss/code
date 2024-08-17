import pandas as pd

file_path = "a.xlsx"
df = pd.read_excel(file_path)

# filter null data
df = df.dropna()

for a, b, c in zip(df['column_a'], df['column_b'], df['column_c']):
    print(a, b, c)
