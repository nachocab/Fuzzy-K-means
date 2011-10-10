import sys
from random import gauss

# examples
mean = [
    # x    y
    [0.0, 0.0], # cluster 1
    [1.0, 1.0]  # cluster 2
    ]

sd = [
    # x    y
    [1.0, 1.0], # cluster 1
    [1.0, 1.0]  # cluster 2
    ]

msg = 'Usage: python generate-clusters.py filename N mu_x1 mu_y1 sigma_x1 sigma_y1 mu_x2 mu_y2 sigma_x2 sigma_y2 ... \n\
  filename = file in which to store clusters\n\
  N = number of examples to generate for each cluster\n\
  mu_x, mu_y = means along x and y dimensions\n\
  sigma_x, sigma_y = std. devs. along x and y dimensions\n\
  \n\
  specify >= 2 clusters.'

if len(sys.argv) < 11:
    print msg
    sys.exit(-1)
fn = sys.argv[1]
n = int(sys.argv[2])

args = sys.argv[3:]
if (len(args) % 4) != 0:
    print msg
    sys.exit(-1)

k = len(args) / 4
mean = []
sd = []
for i in range(k):
    mu_x = float(args[i*4])
    mu_y = float(args[i*4+1])
    sigma_x = float(args[i*4+2])
    sigma_y = float(args[i*4+3])
    mean.append([mu_x, mu_y])
    sd.append([sigma_x, sigma_y])

def one_sample(which_k):
    x = gauss(mean[which_k][0],sd[which_k][0])
    y = gauss(mean[which_k][1],sd[which_k][1])
    return x,y

def main():
    f = open(fn,'w+')
    for i in range(k):
        for j in range(n):
            x,y = one_sample(i)
            print >>f, '\t'.join([str(x), str(y), str(i)])
    f.close()
    print 'Output saved to %s' % fn


main()
