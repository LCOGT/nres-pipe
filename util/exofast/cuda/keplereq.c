#include <cstdlib>
#include <iostream>
#include <string>
#include <sstream>
#include <cassert>

#include <cuda.h>
#include <cuda_runtime.h>
#include <cutil.h>

#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/tuple.h>
#include <thrust/iterator/zip_iterator.h>
#include <thrust/for_each.h>
  
#define DEBUG_CPU 0

// A bunch of junk to deal with querying GPU info
namespace ebf {
/**
        \brief Unrecoverable error exception.

        Throw an instance of this class to indicate an unrecoverable error
        was encountered. Do not throw it directly, but through the use of ERROR() macro.
*/
class runtime_error : public std::runtime_error
{
public:
        runtime_error(const std::string &msg) : std::runtime_error(msg) {}
        virtual ~runtime_error() throw() {};
};

#ifndef THROW_IS_ABORT
        #define ERROR(msg) throw ebf::runtime_error(msg);
#else
        #define ERROR(msg) { fprintf(stderr, "%s\n", std::string(msg).c_str()); abort(); }
#endif


/*!  Unrecoverable CUDA error, thrown by cudaErrCheck macro.
 *    Do not use directly. use cudaErrCheck macro instead.
 */
struct cudaException : public ebf::runtime_error
{
        cudaException(cudaError err) : ebf::runtime_error( cudaGetErrorString(err) ) {}

        static void check(cudaError err, const char *fun, const char *file, const int line) {
                if(err != cudaSuccess)
                        throw cudaException(err);
        }
};
/**
 *      cudaErrCheck macro -- aborts with message if the enclosed call returns != cudaSuccess
 */
#define cudaErrCheck(expr) \
        cudaException::check(expr, __PRETTY_FUNCTION__, __FILE__, __LINE__)

}

// global variables for timing code
uint memoryTime, kernelTime;


// Code that gets turned into a GPU kernel by thrust
struct keplereq_functor
{
	static const double del_sq = 1.0e-12;
    	static const double k = 0.85;
	static const int num_max_it = 20;
	static const double third = 1.0/3.0;

	keplereq_functor() { };

#if !DEBUG_CPU
	__device__ 
#endif
	__host__ inline void operator()( thrust::tuple<const double&,const double&, double&>  val )
	{
	double M = thrust::get<0>(val);
	double e = thrust::get<1>(val);
#if DEBUG_CPU
	assert(M>=0.);
	assert(M<=2.*M_PI);
	assert(e>=0.);
	assert(e<=1.);
#endif
 	double x = (M<M_PI) ? M + k*e : M - k*e;
    	double F = 1.;
    	for(int i=0;i<num_max_it;++i)
	   {
	   double es, ec;
 	   sincos(x,&es,&ec);
           es *= e;
           F = (x-es)-M;
           if(fabs(F)<del_sq) break;
           ec *= e;
 	   const double Fp = 1.-ec;
           const double Fpp = es;
           const double Fppp = ec;
           double Dx = -F/Fp;
           Dx = -F/(Fp+0.5*Dx*Fpp);
       	   Dx = -F/(Fp+0.5*Dx*(Fpp+third*Dx*Fppp));
           x += Dx;
      	   }
	thrust::get<2>(val) = x;
	};
};


// selects GPU to use and returns gpu ID or -1 if using CPU
int init_cuda() 
{ 
    // Select the proper device
    const char* devstr = getenv("CUDA_DEVICE");
    const int env_dev = (devstr != NULL) ? atoi(devstr) : 0;
    int dev = env_dev;
    int devcnt; ebf::cudaErrCheck( cudaGetDeviceCount(&devcnt) );
    if( dev >= 0 && dev < devcnt )
       { 
       ebf::cudaErrCheck( cudaSetDevice(dev) ); 
       cudaDeviceSetCacheConfig(cudaFuncCachePreferL1);
       }
    else
       {
        dev = -1;
       	std::cerr << "# Cannot select the CUDA device. Using CPU!" << std::endl;
	}
    return dev;
}


// keplereq_wrapper_C:
//         C wrapper function to solve's Kepler's equation num times.  
// inputs: 
//         ph_ma:  pointer to beginning element of array of doubles containing mean anomaly in radians 
//         ph_ecc: pointer to beginning element of array of doubles containing eccentricity 
//         num:    integer size of input arrays 
//         ph_eccanom: pointer to beginning element of array of doubles eccentric anomaly in radians 
// outputs:
//         ph_eccanom: values overwritten with eccentric anomaly
// assumptions:
//         input mean anomalies between 0 and 2pi
//         input eccentricities between 0 and 1
//         all three arrays have at least num elements 
//
void keplereq_wrapper_c(double *ph_ma, double *ph_ecc, int num, double *ph_eccanom)
{
	int gpuid = init_cuda();
	// put vectors in thrust format from raw points
	thrust::host_vector<double> h_ecc(ph_ecc,ph_ecc+num);
	thrust::host_vector<double> h_ma(ph_ma,ph_ma+num);

	cutCreateTimer(&memoryTime);  	cutCreateTimer(&kernelTime);
	cutResetTimer(memoryTime);    	cutResetTimer(kernelTime);

	if(gpuid>=0)
	{
	cutStartTimer(memoryTime);
	// transfer input params to GPU
	thrust::device_vector<double> d_ecc = h_ecc;
	thrust::device_vector<double> d_ma = h_ma;
	// allocate mem on GPU
	thrust::device_vector<double> d_eccanom(num);
	cudaThreadSynchronize();
	cutStopTimer(memoryTime);
	
	// distribute the computation to the GPU
	cutStartTimer(kernelTime);
	thrust::for_each(
	   thrust::make_zip_iterator(thrust::make_tuple(d_ma.begin(),d_ecc.begin(),d_eccanom.begin())),
	   thrust::make_zip_iterator(thrust::make_tuple(d_ma.end(),  d_ecc.end(),  d_eccanom.end())), 
	   keplereq_functor() );
	cudaThreadSynchronize();
	cutStopTimer(kernelTime);

	// transfer results back to host
	cutStartTimer(memoryTime);
	thrust::copy(d_eccanom.begin(),d_eccanom.end(),ph_eccanom);
	cudaThreadSynchronize();
	cutStopTimer(memoryTime);
	}
	else
	{
	// distribute the computation to the CPU
	cutStartTimer(kernelTime);
	thrust::for_each(
	   thrust::make_zip_iterator(thrust::make_tuple(h_ma.begin(),h_ecc.begin(),ph_eccanom)),
	   thrust::make_zip_iterator(thrust::make_tuple(h_ma.end(),  h_ecc.end(),  ph_eccanom+num)), 
	   keplereq_functor() );
	cutStopTimer(kernelTime);	
	}
}


// demo program for how to use
// 	keplereq_wrapper_c(ph_ma,ph_ecc,num_eval,ph_eccanom);
// command line arguments:
//      number of eccentricities
//      number of mean anomalies
//      verbose (0, 1, 2)
// example:  ./keplereq.exe 4096 8192 0
// performance note:  
//      For just solving Kepler's equation, CPU<->GPU memory transfer overhead 
// 	is several times more expensive than the actual calculations.
//	So you might as well calculate it many times.
//      Eventually move more calculations onto GPU to amortize memory transfer
//      On GF100, 32M evals take a total of 256ms, of which 213ms is memory
//
int main(int argc, char **argv)
{
	// set size parameters from defaults or command line
	int num_ecc = 4096;
	int num_ma = 4096;
	int verbose = 0;
	{
	std::istringstream iss;
	if(argc>1)
		{
		iss.str(std::string (argv[1]));
		iss >> num_ecc;
		iss.clear();
		}
	if(argc>2)
		{
		iss.str(std::string (argv[2]));
		iss >> num_ma;
		iss.clear();
		}
	if(argc>3)
		{
		iss.str(std::string (argv[3]));
		iss >> verbose;
		iss.clear();
		}
	}
	int num_eval = num_ecc*num_ma;

	std::cerr << "# num_ecc = " << num_ecc << " num_meannom = " << num_ma << " verbose = " << verbose << "\n";

	// allocate host memory
	thrust::host_vector<double> h_ecc(num_eval);
	thrust::host_vector<double> h_ma(num_eval);
	thrust::host_vector<double> h_eccanom(num_eval);

	// initialize data on host 
	for(int i=0;i<num_ecc;++i)
		{
		for(int j=0;j<num_ma;++j)
			{	
			int k = i*num_ma+j;
			h_ecc[k] = 0.3;//static_cast<double>(i)/static_cast<double>(num_ecc);
			h_ma[k]  = 2.*M_PI*static_cast<double>(j)/static_cast<double>(num_ma);
			}
		}

	// optional check up on input values
	if(verbose>1)
	   {
		for(int i = 0; i < h_ecc.size(); i++)
        	   std::cout << "p[" << i << "] = " << h_ecc[i] << std::endl;

		for(int i = 0; i < h_ma.size(); i++)
		   std::cout << "z[" << i << "] = " << h_ma[i] << std::endl;
	   }

	// extract raw pointers to host memory to simulate what you'd get from IDL or another library
	double *ph_ecc = &h_ecc[0]; 
	double *ph_ma = &h_ma[0]; 
	double *ph_eccanom = &h_eccanom[0];

	// wrapper function that could be called from IDL
	keplereq_wrapper_c(ph_ma,ph_ecc,num_eval,ph_eccanom);

	// print results to verify that this worked (optional)
	if(verbose>0)
	   {
	   for(int i = 0; i < h_eccanom.size(); i++)
	      std::cout << i << ' ' << h_ecc[i] << ' ' << h_ma[i] << ' ' << ph_eccanom[i] << std::endl;	
	   }

	// report time spent on calculations and memory transfer
	std::cerr << "# Time for kernel: " << cutGetTimerValue(kernelTime) << " ms, Time for memory: " << cutGetTimerValue(memoryTime) << " ms, Total time: " << cutGetTimerValue(kernelTime)+cutGetTimerValue(memoryTime) << " ms \n"; 
	
}

extern "C" {
  #include <stdio.h>
  #include "idl_export.h"

  double keplereq_cuda(int argc, void *argv[]) {
    keplereq_wrapper_c((double *) argv[0], (double *) argv[1], (IDL_LONG64) argv[2], (double *) argv[3]);  
    return -1; 
  }
}
