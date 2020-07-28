"""
    Util functions
"""
import cProfile
import logging
import pstats
import time as time
from pstats import SortKey

import numpy as np

TIME_STATS = {}

logger = logging.getLogger('time')
logger.setLevel(logging.INFO)

# TODO: ggf. auch mal mit PERF was machen


def profiling(profunc):
    def prof_wrapper(*args, **kwargs):
        with cProfile.Profile() as pr:
            value = profunc(*args, **kwargs)
        p = pstats.Stats(pr)
        p.sort_stats(SortKey.TIME).dump_stats(
            f"profiles/{profunc.__name__}_{args[0]}.prof")
        return value
    return prof_wrapper


def timer(func):
    def wrapper(*args, **kwargs):
        before = time.perf_counter()
        value = func(*args, **kwargs)
        after = time.perf_counter() - before
        if func.__name__ not in TIME_STATS:
            TIME_STATS[func.__name__] = [0, 0]
        TIME_STATS[func.__name__][0] += 1
        TIME_STATS[func.__name__][1] += after

        logger.info(f"{func.__name__}({args}) took {after:.6}")

        return value
    return wrapper


def MatrixGenerator(dim, max_value=500):
    return np.random.rand(*dim) * np.random.randint(max_value)
