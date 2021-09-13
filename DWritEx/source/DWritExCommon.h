// For Windows 8 systems where it is already defined.
__if_exists(DX_MATRIX_3X2F)
{
    inline const DWRITE_MATRIX* CastToDWrite(const DX_MATRIX_3X2F* matrix)
    {
        return matrix; // no-op
    }

    inline const D2D1_MATRIX_3X2_F* CastToD2D(const DX_MATRIX_3X2F* matrix)
    {
        return matrix; // no-op
    }
}

// For older systems where it is not defined, such as Windows 7/Vista.
__if_not_exists(DX_MATRIX_3X2F)
{
    // Union of D2D and DWrite's matrix to facilitate
    // usage between them, while not breaking existing
    // applications that use one or the other.
    union DX_MATRIX_3X2F
    {
        // Explicity named fields for clarity.
        struct { // Win8
            FLOAT xx; // x affects x (horizontal scaling / cosine of rotation)
            FLOAT xy; // x affects y (vertical shear     / sine of rotation)
            FLOAT yx; // y affects x (horizontal shear   / negative sine of rotation)
            FLOAT yy; // y affects y (vertical scaling   / cosine of rotation)
            FLOAT dx; // displacement of x, always orthogonal regardless of rotation
            FLOAT dy; // displacement of y, always orthogonal regardless of rotation
        };
        struct { // D2D Win7
            FLOAT _11;
            FLOAT _12;
            FLOAT _21;
            FLOAT _22;
            FLOAT _31;
            FLOAT _32;
        };
        struct { // DWrite Win7
            FLOAT m11;
            FLOAT m12;
            FLOAT m21;
            FLOAT m22;
            FLOAT m31;
            FLOAT m32;
        };
        float m[6]; // Would [3][2] be better, more useful?

        DWRITE_MATRIX dwrite;
        D2D1_MATRIX_3X2_F d2d;
    };

    inline const DWRITE_MATRIX* CastToDWrite(const DX_MATRIX_3X2F* matrix)
    {
        return reinterpret_cast<const DWRITE_MATRIX*>(matrix);
    }

    inline const D2D1_MATRIX_3X2_F* CastToD2D(const DX_MATRIX_3X2F* matrix)
    {
        return reinterpret_cast<const D2D1_MATRIX_3X2_F*>(matrix);
    }
}

