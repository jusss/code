import asyncio
@asyncio.coroutine
def p():
    print('hello')
    yield from asyncio.sleep(0.5)
    print('world')
@asyncio.coroutine
def p2():
    print('john')
    yield from asyncio.sleep(0.5)
    print('it is')

def p3(f):
    print(f.result())
    
loop=asyncio.new_event_loop()
asyncio.set_event_loop(loop)

task = [asyncio.ensure_future(p()), asyncio.ensure_future(p2())]
task[1].add_done_callback(p3)
#task = [p(), p2()]
loop.run_until_complete(asyncio.wait(task))

#asyncio.run(p())
#asyncio.run(p2())

#async def define a function, call that function and it return a coroutine object
#asyncio.ensure_future on that coroutine object and return a future object
#asyncio.get_event_loop() return a loop, loop.run_until_complete work on
# that future object, 
#task object is sub-class of future object
#loop.run_until_complete will auto turn coroutine object to task object
#loop.create_task(coroutine-object) to task object, same to asyncio.ensure_future(coroutine-object)
#print that future object to know its state
#future object has add_done_callback(callback-function) and that callback-function defined with future as parameter
#
#RuntimeError: There is no current event loop in thread 'MainThread'.
#every thread only has one event-loop, if you use asyncio.get_event_loop it will auto create one event loop
#and set it as default event-loop in current thread, if you call it in other threads so it will be error
#you need create it and set it by hand, loop=asyncio.new_event_loop(); asyncio.set_event_loop(loop)
#then you can use  get_event_loop in other threads
#loop.call_soon_threadsafe(task)
