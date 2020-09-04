module multid.multigrid.prolongation;

import mir.ndslice;

/++
This is the implementation of a prolongation
    Params:
        e = the grid that needs to be prolongated
        fine_shape = the shape of the returned grid
        returns the finer grid with interpolated values in between
+/
Slice!(T*, Dim) prolongation(T, size_t Dim)(in Slice!(T*, Dim) e, in size_t[Dim] fine_shape)
{
    auto w = slice!T(fine_shape, 0);
    auto end = e.shape[0] - (fine_shape[0] + 1) % 2;
    auto wend = w.shape[0] - (fine_shape[0] + 1) % 2;
    auto WF = w.field;
    auto EF = e.field;

    static if (Dim == 1)
    {
        for (size_t i = 1; i < end; i++)
        {
            w.field[2 * i - 1] = (e.field[i - 1] + e.field[i]) / 2;
            w.field[2 * i] = e.field[i];
        }
        w.field[$ - 1] = e.field[$ - 1];
    }
    else static if (Dim == 2)
    {
        foreach (i; 0 .. end - 1)
        {
            auto flatindexw = 2 * i * w.shape[0];
            auto flatindexw2 = (2 * i + 1) * w.shape[0];
            auto flatindexe = i * e.shape[0];
            auto flatindexe2 = (i + 1) * e.shape[0];
            foreach (j; 0 .. end - 1)
            {
                // the value that is copied
                WF[flatindexw + 2 * j] = EF[flatindexe + j];
                // the value next a copied one
                WF[flatindexw + 2 * (j + 1) - 1] = (EF[flatindexe + j] + EF[flatindexe + j + 1]) / 2;
                // the value below a copied one
                WF[flatindexw2 + 2 * j] = (EF[flatindexe2 + j] + EF[flatindexe + j]) / 2;
            }
            WF[flatindexw + 2 * (end - 1)] = EF[flatindexe + end - 1];
            WF[flatindexw2 + 2 * (end - 1)] = (EF[flatindexe2 + end - 1] +
                    EF[flatindexe + end - 1]) / 2;
        }
        // this is for the last row and the last colomn
        auto flatindexw = 2 * (end - 1) * w.shape[0];
        auto flatindexe = (end - 1) * e.shape[0];
        foreach (j; 0 .. end - 1)
        {
            WF[flatindexw + 2 * j] = EF[flatindexe + j];
            WF[flatindexw + 2 * (j + 1) - 1] = (EF[flatindexe + j] + EF[flatindexe + j + 1]) / 2;
        }
        WF[$ - 1] = EF[$ - 1];
        for (size_t i = 1; i < wend; i += 2)
        {
            for (size_t j = 1; j < wend; j += 2)
            {
                auto flatindex = i * w.shape[0] + j;
                WF[flatindex] = (
                        WF[flatindex + w.shape[0]] + WF[flatindex -
                        w.shape[0]] + WF[flatindex - 1] + WF[flatindex + 1]) / 4;
            }
        }
        // Since we restrict always to N//2 + 1 we need to handle the case if
        // the finer grid is even sized, because that means between the last
        // and the forelast is no new colomn that needs to be calculated
        if (fine_shape[0] % 2 != e.shape[0] % 2)
        {
            flatindexw = (w.shape[0] - 1) * w.shape[0];
            flatindexe = (e.shape[0] - 1) * e.shape[0];
            foreach (j; 0 .. end - 1)
            {
                WF[flatindexw + 2 * j] = EF[flatindexe + j];
                WF[flatindexw + 2 * (j + 1) - 1] = (EF[flatindexe + j] + EF[flatindexe + j + 1]) / 2;

                WF[(w.shape[0]) * 2 * j + w.shape[0] - 1] = EF[(
                            e.shape[0]) * j + e.shape[0] - 1];

                WF[w.shape[0] * (2 * j + 1) + w.shape[0] - 1] = (
                        EF[e.shape[0] * j + e.shape[0] - 1] +
                        EF[e.shape[0] * (j + 1) + e.shape[0] - 1]) / 2;
            }
            w[$ - 2 .. $, $ - 2 .. $] = e[$ - 2 .. $, $ - 2 .. $];

        }

    }
    else static if (Dim == 3)
    {
        //TODO
        static assert(false, Dim.stringof ~ "not implementet yet");
    }
    else
    {
        static assert(false, Dim.stringof ~ " is not a supported dimension!");
    }
    return w;
}

// Tests 1D
unittest
{

    auto a = [0, 2, 4, 6, 8].sliced!long;
    auto correct = 9.iota.slice;
    auto ret = prolongation!(long, 1)(a, correct.shape);
    assert(ret == correct);

    auto a2 = [0, 2, 4, 6, 8, 9].sliced!long;
    auto correct2 = 10.iota.slice;
    auto ret2 = prolongation!(long, 1)(a2, correct2.shape);
    assert(ret2 == correct2);

    auto a3 = [0, 2, 4, 6, 7].sliced!long;
    auto correct3 = 8.iota.slice;
    auto ret3 = prolongation!(long, 1)(a3, correct3.shape);
    assert(ret3 == correct3);

}

// Tests 2D
unittest
{
    auto arr = [0., 2., 4., 6., 8.,
        18., 20., 22., 24., 26.,
        36., 38., 40., 42., 44.,
        54., 56., 58., 60., 62.,
        72., 74., 76., 78., 80.].sliced(5, 5);

    auto correct = iota([9, 9]).slice;
    auto ret = prolongation!(double, 2)(arr, correct.shape);
    assert(ret == correct);
    auto arr2 = [0., 2., 4., 6., 7., 16., 18., 20., 22., 23., 32., 34., 36.,
        38., 39., 48., 50., 52., 54., 55., 56., 58., 60., 62., 63.].sliced(5, 5);
    auto correct2 = iota([8, 8]).slice;
    auto ret2 = prolongation!(double, 2)(arr2, correct2.shape);
    assert(ret2 == correct2);
}