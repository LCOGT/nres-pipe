import trace_orders
import numpy as np
import pytest

#def test_find_next_order():
    

#def test_find_next_fiber():

#def test_guess_point():

#def test_fit_polynomial():

#def test_follow_fiber():

#def test_get_flux():

#def test_get_slice():

#def test_get_centroid():

# def test_get_remove_bkgd(): #maybe more descriptive
#     inp = np.array([1,2,3,5])
#     out = trace_orders.get_remove_bkgd(inp)
#     ans = np.array([0,1,2,4])
#     assert np.array_equal(out,ans)

def test_print_progress():
    returned_vals = []
    last_printed = 0
    ntot = 100
    for i in range(0,ntot):
        last_printed = trace_orders.print_progress(i,last_printed,ntot,report=10,msg='test :')
        returned_vals.append(last_printed)
    print(returned_vals)
    assert False
    
#def test_mytest()
#    with pytest.raises(the exception name):
#       run the code