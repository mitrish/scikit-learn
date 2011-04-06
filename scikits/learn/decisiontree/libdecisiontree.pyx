"""
Binding for libdecisiontree
---------------------------

Notes
-----

Authors
-------
2011: Noel Dawe <Noel.Dawe@cern.ch>
"""

import  numpy as np
cimport numpy as np

################################################################################
# Includes

cdef extern from "Node.h":
    cdef cppclass Node:
        Node(double, double)
        void recursive_split(int, int)

cdef class PyNode:
    cdef Node *thisptr
    def __cinit__(self, double sig_score, double bkg_score):
        self.thisptr = new Node(sig_score, bkg_score)
    def __dealloc__(self):
        del self.thisptr

cdef extern from "libdecisiontree_helper.cpp":
    void copy_predict (char*, Node*, np.npy_intp*, char*)
    void init_root(char*, char*, char*, np.npy_intp*, Node*)

################################################################################
# Wrapper functions

def fit(np.ndarray[np.float64_t, ndim=2, mode='c'] X,
        np.ndarray[np.float64_t, ndim=1, mode='c'] Y,
        np.ndarray[np.float64_t, ndim=1, mode='c'] sample_weight = np.empty(0),
        int minleafsize = 10,
        int nbins = 0,
        double sig_score = 1.,
        double bkg_score = -1.):

    """
    Parameters
    ----------
    X: array-like, dtype=float, size=[n_samples, n_features]

    Y: array, dtype=float, size=[n_samples]
        target vector

    Return
    ------
    root: root Node of the trained decision tree

    classification : resulting classification of the training set
    """
    cdef PyNode root

    root = PyNode(sig_score, bkg_score)
    init_root(X.data, Y.data, sample_weight.data, X.shape, root.thisptr)
    root.thisptr.recursive_split(minleafsize, nbins)
    
    return root

def predict(np.ndarray[np.float64_t, ndim=2, mode='c'] X,
            PyNode root):
    """
    Predict target values of X given a model (low-level method)

    Parameters
    ----------
    X: array-like, dtype=float, size=[n_samples, n_features]

    root: decision tree root Node

    Return
    ------
    dec_values : array
        predicted values.
    """
    cdef np.ndarray[np.float64_t, ndim=1, mode='c'] dec_values
    
    dec_values = np.empty(X.shape[0])
    copy_predict(X.data, root.thisptr, X.shape, dec_values.data)
    return dec_values
