import logging
import sys

import numpy as np

import multipy.tools.heatmap as hm
import multipy.tools.util as util


logging.basicConfig(level=logging.INFO)

np.set_printoptions(precision=4, linewidth=180)


@util.profiling
def profile_2D_multigrid(N, numba=True):
    iter_cycle = 1000
    U = hm.initMap_2D(N)
    F = hm.heat_sources_2D(N)
    hm.poisson_multigrid(F, U, 5, 2, 2, 2, iter_cycle, numba=numba)


@util.timer
def time_multigrid(N, numba=True):
    U, F = hm.create_problem_2D(N)
    iter_cycle = 100
    hm.poisson_multigrid(F, U, 5, 2, 2, 2, iter_cycle, numba=numba)


if __name__ == "__main__":
    numba = True
    if len(sys.argv) == 2:
        numba = util.str2bool(str(sys.argv[1]))
    for i in range(8, 14):
        profile_2D_multigrid(2**i, numba)
