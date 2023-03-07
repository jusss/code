import matplotlib.pyplot as plt
import numpy as np


# bar
#left = [1, 2, 3, 4,5]
#height = [0.01, 0.02, 0.03, 0.04, 0.05]
#tick_label = ['30m', '60m', '90m', '120m', '150m']
#plt.bar(left, height, tick_label = tick_label, width = 0.3, color = ['yellow','green','red'])


# plot
x = np.arange(0, 160, 40)
y1 = [0.04, 0.03, 0.08, 0.09]
y2 = [0.08, 0.06, 0.09, 0.12]
y3 = [0.06, 0.04, 0.03, 0.03]
plt.plot(x,y1, label='X')
plt.plot(x,y2, label='V')
plt.plot(x,y3, label='Y')

plt.xlabel('X(m)')
plt.ylabel('Y(%)')
plt.title('test')
plt.legend(loc='best')
plt.show()

