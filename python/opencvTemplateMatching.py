import cv2 as cv
import numpy as np

img_rgb = cv.imread('/sdcard/wnyphone/icon/1620977758114.png')
img_gray = cv.cvtColor(img_rgb, cv.COLOR_BGR2GRAY)
template = cv.imread('/sdcard/wnyphone/icon/template.jpg',0)
w, h = template.shape[::-1]

res = cv.matchTemplate(img_gray,template,cv.TM_CCOEFF_NORMED)
threshold = 0.8
loc = np.where( res >= threshold)
leftCorner = (0,0)

for pt in zip(*loc[::-1]):
    cv.rectangle(img_rgb, pt, (pt[0] + w, pt[1] + h), (0,0,255), 2)
    leftCorner = pt

cv.imwrite('res.png',img_rgb)
print("left corner is")
print(leftCorner)
print("right corner is")
print(leftCorner[0]+w, leftCorner[1]+h)
print("center is")
cx = leftCorner[0] + w/2
cy = leftCorner[1] + h/2
print(cx)
print(cy)
