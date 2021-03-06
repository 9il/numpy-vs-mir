import numpy as np
from numba import jit


def prolongation(e, fine_shape):
    """
    This interpolates/ prolongates to a grid of fine_shape
    @param e
    @param fine_shape targeted shape
    @return grid with fine_shape
    """

    # indicator for Dimension
    alpha = len(e.shape)
    # initialize result with respect to the wanted shape
    w = np.zeros(fine_shape)
    # Index of the second to the last element to mention in e (depends on the
    # shape of w)
    end = e.shape[0] - (w.shape[0] + 1) % 2
    # Index of the second to the last element to mention in w (depends on the
    # shape of w)
    wend = w.shape[0] - (w.shape[0] + 1) % 2

    # Case: Dimension 1
    if alpha == 1:
        prolongation_1D(w, e, end)
    # Case: Dimension 2
    elif alpha == 2:
        prolongation_2D(w, e, end, wend)
    # Case: Dimension 3
    elif alpha == 3:
        prolongation_3D(w, e, end, wend)

    # Case: Error
    else:
        raise ValueError("prolongation: invalid dimension")
    return w


@jit(nopython=True, fastmath=True)
def prolongation_1D(w, e, end):
    # copy e to every second index in w
    w[:-1:2] = e[:-1]
    # Interpolate the missing elements in w with their two neighbors
    w[1:-1:2] = (e[: end - 1] + e[1:end]) / 2
    # set last index since this one was skipped before
    w[-1] = e[-1]


@jit(nopython=True, fastmath=True)
def prolongation_2D(w, e, end, wend):
    # copy elements from e to w
    w[:-1:2, :-1:2] = e[:-1, :-1]
    w[:-1:2, -1] = e[:-1, -1]
    w[-1, :-1:2] = e[-1, :-1]
    w[-1, -1] = e[-1, -1]

    # interpolate elements horizontally
    w[:-1:2, 1:-1:2] = (e[:-1, : end - 1] + e[:-1, 1:end]) / 2
    w[-1, 1:-1:2] = (e[-1, : end - 1] + e[-1, 1:end]) / 2

    # interpolate elements vertically
    w[1:-1:2, :-1:2] = (e[: end - 1, :-1] + e[1:end, :-1]) / 2
    w[1:-1:2, -1] = (e[: end - 1, -1] + e[1:end, -1]) / 2

    # interpolate missing elements: average of 4 neighbors
    w[1:-1:2, 1:-1:2] = (
        w[2:wend:2, 1:wend:2] +
        w[: wend - 1: 2, 1:wend:2] +
        w[1:wend:2, : wend - 1: 2] +
        w[1:wend:2, 2:wend:2]
    ) / 4


@jit(nopython=True, fastmath=True)
def prolongation_3D(w, e, end, wend):
    # copy elements from e to w
    w[:-1:2, :-1:2, :-1:2] = e[:-1, :-1, :-1]
    w[:-1:2, -1, -1] = e[:-1, -1, -1]
    w[-1, :-1:2, -1] = e[-1, :-1, -1]
    w[-1, -1, :-1:2] = e[-1, -1, :-1]
    w[:-1:2, :-1:2, -1] = e[:-1, :-1, -1]
    w[:-1:2, -1, :-1:2] = e[:-1, -1, :-1]
    w[-1, :-1:2, :-1:2] = e[-1, :-1, :-1]
    w[-1, -1, -1] = e[-1, -1, -1]

    # interpolate elements horizontally
    w[:-1:2, 1:-1:2, :-1:2] = (
        e[:-1, : end - 1, :-1] + e[:-1, 1:end, :-1]
    ) / 2
    w[:-1:2, -1, 1:-1:2] = (e[:-1, -1, : end - 1] + e[:-1, -1, 1:end]) / 2
    w[:-1:2, :-1:2, 1:-1:2] = (
        e[:-1, :-1, : end - 1] + e[:-1, :-1, 1:end]
    ) / 2
    w[:-1:2, 1:-1:2, -1] = (e[:-1, : end - 1, -1] + e[:-1, 1:end, -1]) / 2
    w[:-1:2, 1:-1:2, 1:-1:2] = (
        e[:-1, : end - 1, : end - 1] +
        e[:-1, 1:end, 1:end] +
        e[:-1, : end - 1, 1:end] +
        e[:-1, 1:end, : end - 1]) / 4

    # special case
    w[-1, 1:-1:2, :-1:2] = (e[-1, : end - 1, :-1] + e[-1, 1:end, :-1]) / 2
    w[-1, -1, 1:-1:2] = (e[-1, -1, : end - 1] + e[-1, -1, 1:end]) / 2
    w[-1, :-1:2, 1:-1:2] = (e[-1, :-1, : end - 1] + e[-1, :-1, 1:end]) / 2
    w[-1, 1:-1:2, -1] = (e[-1, : end - 1, -1] + e[-1, 1:end, -1]) / 2
    w[-1, 1:-1:2, 1:-1:2] = (
        e[-1, : end - 1, : end - 1] +
        e[-1, 1:end, 1:end] +
        e[-1, : end - 1, 1:end] +
        e[-1, 1:end, : end - 1]
    ) / 4

    # interpolate elements vertically
    w[1:-1:2, :-1:2, :-1:2] = (
        e[: end - 1, :-1, :-1] + e[1:end, :-1, :-1]
    ) / 2
    w[1:-1:2, -1, :-1:2] = (e[: end - 1, -1, :-1] + e[1:end, -1, :-1]) / 2
    w[1:-1:2, :-1:2, -1] = (e[: end - 1, :-1, -1] + e[1:end, :-1, -1]) / 2
    w[1:-1:2, -1, -1] = (e[: end - 1, -1, -1] + e[1:end, -1, -1]) / 2
    w[1:-1:2, -1, 1:-1:2] = (
        w[1:-1:2, -1, : wend - 1: 2] + w[1:-1:2, -1, 2:wend:2]
    ) / 2
    w[1:-1:2, :-1:2, 1:-1:2] = (
        w[1:-1:2, :-1:2, : wend - 1: 2] + w[1:-1:2, :-1:2, 2:wend:2]
    ) / 2
    w[1:-1:2, 1:-1:2, -1] = (
        w[1:-1:2, : wend - 1: 2, -1] + w[1:-1:2, 2:wend:2, -1]
    ) / 2
    w[1:-1:2, 1:-1:2, :-1:2] = (
        w[1:-1:2, : wend - 1: 2, :-1:2] + w[1:-1:2, 2:wend:2, :-1:2]
    ) / 2
    w[1:-1:2, 1:-1:2, 1:-1:2] = (
        w[1:-1:2, 1:-1:2, : wend - 1: 2] + w[1:-1:2, 1:-1:2, 2:wend:2]
    ) / 2
