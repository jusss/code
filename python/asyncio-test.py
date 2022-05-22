
import asyncio, time, datetime

async def loop1():
    print(datetime.datetime.now(), f"loop1 is created")
    n=1
    while n<6:
        print(datetime.datetime.now(), f"loop1, {n}")
        n=n+1
        await asyncio.sleep(2)
    return 1

async def loop2():
    print(datetime.datetime.now(), f"loop2 is created")
    n=1
    while n<6:
        print(datetime.datetime.now(), f"loop2, {n}")
        n=n+1
        await asyncio.sleep(3)
    return 2

async def loop3():
    n=1
    while n<3:
        print("loop3")
        n=n+1
        await asyncio.sleep(1)
    return 3

async def loop4():
    n=1
    while n<3:
        print("loop4")
        n=n+1
        await asyncio.sleep(1)
    return 4

#async def main():
    #L = await asyncio.gather(loop1(),loop2())
    #print(L)
    #r3 = await loop3()
    #print(r3)

async def main():
    _loop1 = loop1()
    # asyncio.create_task will run immediately, like kotlin's async {...}
    # task1 and task2 will run parallelism, and task4 will run after task1 is done
    task1=asyncio.create_task(_loop1)
    task2=asyncio.create_task(loop2())

    # await will block and wait the result
    await task1
    task4=asyncio.create_task(loop4())

    await task2
    task3=asyncio.create_task(loop3())

    # you need await to block the result, otherwise it will end too soon
    #await task3
    # doSomething
    #await task4
    # same to
    await asyncio.gather(task3, task4)


asyncio.run(main())
print("async is done")

#--------------------------------------------------------------
#import asyncio


#async def func(i: int) -> None:
    #for _ in range(i):
        #await asyncio.sleep(1)
    #print(f"Task {i} completed.")


#async def main() -> None:
    #coro1 = func(1)
    #coro2 = func(2)
    #task1 = asyncio.create_task(coro1)
    #task2 = asyncio.create_task(coro2)
    #await task1
    #coro3 = func(3)
    #await asyncio.gather(task2, coro3)


#asyncio.run(main())
