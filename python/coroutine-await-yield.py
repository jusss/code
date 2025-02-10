import asyncio
async def f(g):
    n=0
    while True:
        n=n+1
        print(f"f {n}")
        async for i in g(n):
            n=i
            await asyncio.sleep(1)

async def g(n):
    while True:
        n=n+1
        print(f"g {n}")
        yield n
        await asyncio.sleep(1)

async def main():
    await asyncio.create_task(f(g))

if __name__ == '__main__':
    asyncio.run(main())



# # print(next(g(next(f(1)))))
# f_gen = f(1)
# f_value = next(f_gen)

# g_gen = g(2)
# g_value = next(g_gen)

# # print(type(f_gen.send(9)))

# # while True:
    # # n = next(f_gen)
    # # g_gen = g(n)
    # # f_gen = f(next(g_gen))


# for i in range(20):
    # f_value = f_gen.send(g_value)
    # g_value = g_gen.send(f_value)

# # change this to async yield
