import pandas as pd

files = ["query9.xlsx",  "query7.xlsx",  "query10.xlsx","query8.xlsx",  "query5.xlsx",  "query4.xlsx","query3.xlsx",  "query2.xlsx",  "query1.xlsx",  "query0.xlsx", "query6.xlsx"]

data=[]


for filename in files:
    df2 = pd.read_excel(filename)
    query2 = list(df2["query"])
    answer2 = list(df2["gen_answer"])

    for q,a in zip(query2, answer2):
        if not pd.isnull(a):
            data.append({'query': q, 'answer': a})


# ndf = pd.DataFrame(query3, columns=['query'])
# ndf.to_excel(f"New-{output_filename}.xlsx", index=False)

df3 = pd.DataFrame(data)
df3.to_excel('various3000.xlsx', index=False, columns=['query', 'answer'])
