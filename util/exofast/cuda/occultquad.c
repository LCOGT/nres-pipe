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
#include <thrust/iterator/constant_iterator.h>
#include <thrust/iterator/counting_iterator.h>
#include <thrust/sequence.h>
#include <thrust/iterator/zip_iterator.h>
#include <thrust/binary_search.h>
#include <thrust/tuple.h>
#include <thrust/sort.h>
  
#if 0 // potential optimization
#include <thrust/experimental/cuda/pinned_allocator.h> 
typedef thrust::experimental::cuda::pinned_allocator<double> AllocPinned;
thrust::device_vector< double, AllocPinned> pinned_host_vec(num);
T *h_ptr = pinned_host_vec.data();
T *raw_d_ptr = 0;
cudaHostGetDevicePointer(&raw_d_ptr, h_ptr, 0);
thrust::device_ptr<T> dt_ptr(raw_dt_ptr);
thrust::host_ptr<T> ht_ptr(h_ptr,h_ptr+num);
#endif


#define DEBUG_CPU 0
#define SQR(x) ((x)*(x))

// A bunch of junk to deal with querying GPU info
namespace ebf_cuda {
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
        #define ERROR(msg) throw ebf_cuda::runtime_error(msg);
#else
        #define ERROR(msg) { fprintf(stderr, "%s\n", std::string(msg).c_str()); abort(); }
#endif


/*!  Unrecoverable CUDA error, thrown by cudaErrCheck macro.
 *    Do not use directly. use cudaErrCheck macro instead.
 */
struct cudaException : public ebf_cuda::runtime_error
{
        cudaException(cudaError err) : ebf_cuda::runtime_error( cudaGetErrorString(err) ) {}

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

// selects GPU to use and returns gpu ID or -1 if using CPU
int init_cuda() 
{ 
    // Select the proper device
    const char* devstr = getenv("CUDA_DEVICE");
    const int env_dev = (devstr != NULL) ? atoi(devstr) : 0;
    int dev = env_dev;
    int devcnt; ebf_cuda::cudaErrCheck( cudaGetDeviceCount(&devcnt) );
    if( dev >= 0 && dev < devcnt )
       { 
       ebf_cuda::cudaErrCheck( cudaSetDevice(dev) ); 
       cudaDeviceSetCacheConfig(cudaFuncCachePreferL1);
       }
    else
       {
        dev = -1;
       	std::cerr << "# Cannot select the CUDA device. Using CPU!" << std::endl;
	}
    return dev;
}

} // namespace ebf_cuda


// global variables for timing code
uint memoryTime, kernelComputeTime, kernelSortTime;
int verbose;

namespace limbdarkening {

struct ellke_functor
{
   __host__ __device__ inline thrust::tuple<double,double> operator()(const double k)
      {
      double m1 = 1.0-k*k;
      double logm1 = log(m1);
      double ek, kk;
	{
	const double a1=0.44325141463;
	const double a2=0.06260601220;
	const double a3=0.04757383546;
	const double a4=0.01736506451;
	const double b1=0.24998368310;
	const double b2=0.09200180037;
	const double b3=0.04069697526;
	const double b4=0.00526449639;
	const double ee1=1.+m1*(a1+m1*(a2+m1*(a3+m1*a4)));
	const double ee2=m1*(b1+m1*(b2+m1*(b3+m1*b4)))*(-logm1);
	ek = ee1+ee2;
	}	
	{
	const double a0=1.38629436112;
	const double a1=0.09666344259;
	const double a2=0.03590092383;
	const double a3=0.03742563713;
	const double a4=0.01451196212;
	const double b0=0.5;
	const double b1=0.12498593597;
	const double b2=0.06880248576;
	const double b3=0.03328355346;
	const double b4=0.00441787012;
	const double ek1=a0+m1*(a1+m1*(a2+m1*(a3+m1*a4)));
	const double ek2=(b0+m1*(b1+m1*(b2+m1*(b3+m1*b4))))*logm1;
	kk = ek1-ek2;
	}
      return thrust::make_tuple(ek,kk);
      }
};

__host__ __device__ inline double ellpic_bulirsch(const double n, const double k)
{
   double kc = sqrt(1.-k*k);
   double p = n+1.0;
#if CPU_DEBUG
    assert(p>=0.);
#endif
    double m0 = 1.0;
    double c =1.0;
    double d = rsqrt(p);
    p = 1.0/d;
    double e = kc;
    do {
       double f = c;
       c = d/p+c;
       double g = e/p;
       d = 2.*(f*g+d);
       p = g + p;
       g = m0;
       m0 = kc + m0;
       if(SQR(1.0-kc/g)>1.e-16)
       { kc = 2.*sqrt(e);   e = kc*m0; }
       else
       { return 0.5*M_PI*(c*m0+d)/(m0*(m0+p)); }
    } while(true);
}

#define ACCEL_TRIVIAL_RETURN 1
#define GROUP_FUNC_CALLS_MINI 1
#define GROUP_FUNC_CALLS 0 // doesn't help performance

template<bool Uniform>
struct occultquad_functor
{
	 static const double tol = 1.e-14;
	 static const int  z_index = 0;
	 static const int u1_index = 1;
	 static const int u2_index = 2;
	 static const int p0_index = 3;
	 static const int muo1_index = 4;
	 static const int mu0_index = 5;

	 // could optimize further, by multiple if statements, so that only call ellke and ellpic_bulirsch in one place
	 // 
	__host__ __device__ inline 
	// thrust::tuple<double,double> 
	void
	operator()( thrust::tuple< const double&, const double&, const double&, const double&, double&, double& >  val)
	 {
	 ellke_functor ellke;
	 double z  = thrust::get<z_index>(val);
	 const double p0 = thrust::get<p0_index>(val);
	 const double p = fabs(p0); // "to mesh with fitting routines"
#if ACCEL_TRIVIAL_RETURN 
	 if((p<=0.) || (z>=1.+p)) // case 0, 1
	   {
	   thrust::get<muo1_index>(val) = 1.;
	   if(Uniform) thrust::get<mu0_index>(val) = 1.;
	   return ;
	   }
#endif
	 const double u1 = thrust::get<u1_index>(val);
	 const double u2 = thrust::get<u2_index>(val);
	 const double omega = 1.0-(u1-0.5*u2)/3.;
	 double lambdad = 0.;
	 double lambdae = 0.;
	 double etad = 0.;

	 z = (fabs(p-z)<tol) ? p : z;
	 z = (fabs((p-1.)-z)<tol) ? p-1. : z;
	 z = (fabs((1.-p)-z)<tol) ? 1.-p : z;
	 z = (z<tol) ? 0. : z;
	 const double x1 = (p-z)*(p-z);
	 const double x2 = (p+z)*(p+z);

#if !ACCEL_TRIVIAL_RETURN 
         // case 0 and 1 moved up to reduce memory loads
	 if(p<=0.)  // case 0
	   {
	   thrust::get<muo1_index>(val) = 1.;
	   if(Uniform) thrust::get<mu0_index>(val) = 1.;
	   return ;
	   }
	 else if(z>=1.+p) // case 1 // source is unocculted (why so much code?)
	   {
	   thrust::get<muo1_index>(val) = 1.-((1.-u1-2.*u2)*lambdae+(u1+2.*u2)*(lambdad+2./3.*(p > z))+u2*etad)/omega;
	   if(Uniform) thrust::get<mu0_index>(val)  = 1.-lambdae;
	   return ;
	   }
	 else 
#endif
	 if( (p>=1.) && (z<=p-1.) ) // case 11 (source completely occulted)
	   {
	   etad = 0.5;
	   lambdae = 1.;
	   thrust::get<muo1_index>(val) = 1.-((1.-u1-2.*u2)*lambdae+(u1+2.*u2)*(lambdad+2./3.*(p > z))+u2*etad)/omega;
	   if(Uniform) thrust::get<mu0_index>(val)  = 1.-lambdae;
//	   return ;
	   }
	else // partially occulted
	{
	if( (z>=fabs(1.-p)) && (z<1.+p) ) // case 2,7,8 (during ingress/egress)
	   {
	   double tmp1 = (1.-p*p+z*z)/(2.*z);
	   if(tmp1>1.) tmp1 = 1.;	   if(tmp1<-1.) tmp1 = -1.;
	   double kap1 = acos(tmp1);
	   double tmp2 = (p*p+z*z-1.)/(2.*p*z);
	   if(tmp2>1.) tmp2 = 1.;	   if(tmp2<-1.) tmp2 = -1.;
	   double kap0 = acos(tmp2);
	   double tmp3 = 4.*z*z-SQR(1.+z*z-p*p);
//	   double tmp3 = 4.*z*z-(1.+z*z-p*p)*(1.+z*z-p*p);
	   if(tmp3<0.) tmp3 = 0.;
	   lambdae = (p*p*kap0+kap1-0.5*sqrt(tmp3))/M_PI;
	   etad = (kap1+p*p*(p*p+2.*z*z)*kap0-0.25*(1.+5.*p*p+z*z)*sqrt((1.-x1)*(x2-1.)))/(2.*M_PI);
	   // don't return here!
	   }


#if GROUP_FUNC_CALLS 
         // I thought it would be good to parallelize computation of Ek, Kk and elliptic integral
	 // But on test case, it's slower, so I abandonded the idea
	 double q, n;
	 bool compute_EkKk = false, compute_bs = false;
	 if(z==p) // case 5, 6, 7 (edge of planet at origin of star)
	   {  q = (p<=0.5) ? 2.*p : 0.5/p;  compute_EkKk = true; }
	 else if( ((z>0.5+fabs(p-0.5)) && (z<1.+p)) || ((p>0.5) && (z>fabs(1.-p)) && (z<p) ) ) // case 2, 8 (during ingress/egress) (needs etad from uniform disk code)
	   {  
	   q = sqrt((1.-x1)/(4.*p*z));
	   n = 1./x1-1.;          
   	   compute_EkKk = true; compute_bs = true; 
	   }
	 else if((p<1.)&&(z!=1.-p)&&(z!=0.)) // case 3, 9 (planet completely inside star)
	   { 
	   q = rsqrt((1.-x1)/(x2-x1)); 
	   n = x2/x1-1.;
   	   compute_EkKk = true; compute_bs = true; 
	   }
	 thrust::tuple<double,double> EkKk = (compute_EkKk) ? ellke(q) : thrust::make_tuple(0.,0.);
	 double ellpic_bulrisch_n_q = (compute_bs) ? ellpic_bulirsch(n,q) : 0.;
#endif	 
 
	 if(z==p) // case 5, 6, 7 (edge of planet at origin of star)
	   {
#if GROUP_FUNC_CALLS_MINI
	   double q = (p<=0.5) ? 2.*p : 0.5/p;
	   thrust::tuple<double,double> EkKk = (p!=0.5) ? ellke(q) : thrust::make_tuple(0.,0.);
#endif
	   if(p<0.5) // case 5
	     {
#if !GROUP_FUNC_CALLS && !GROUP_FUNC_CALLS_MINI
	     double q = 2.*p;
	     thrust::tuple<double,double> EkKk = ellke(q);
#endif
	     lambdad = 1./3.+2.*(4.*(2.*p*p-1.)*EkKk.get<0>()+(1.-4.*p*p)*EkKk.get<1>())/(9.*M_PI);
	     etad = 0.5*p*p*(p*p+2.*z*z);
	     lambdae = p*p;
	     }
	   else if( p>0.5) // case 7 (need etad from uniform disk code)
	     {
#if !GROUP_FUNC_CALLS && !GROUP_FUNC_CALLS_MINI
	     double q = 0.5/p;
	     thrust::tuple<double,double> EkKk = ellke(q);
#endif
	     lambdad = 1./3.+(16.*p*(2.*p*p-1.)*EkKk.get<0>()-
	       (32.*p*p*p*p-20.*p*p+3.)/(p)*EkKk.get<1>())/(9.*M_PI);
	     }
	   else // case 6
	     {
	     lambdad = 1./3.-4./(9.*M_PI);
	     etad = 3./32.;
	     }
	   thrust::get<muo1_index>(val) = 1.-((1.-u1-2.*u2)*lambdae+(u1+2.*u2)*(lambdad+2./3.*(p > z))+u2*etad)/omega;
	   if(Uniform) thrust::get<mu0_index>(val)  = 1.-lambdae;
//	   return; 
	   }
	 else if( ((z>0.5+fabs(p-0.5)) && (z<1.+p)) || ((p>0.5) && (z>fabs(1.-p)) && (z<p) ) ) // case 2, 8 (during ingress/egress) (needs etad from uniform disk code)
	   {
#if !GROUP_FUNC_CALLS
	   const double q = sqrt((1.-x1)/(4.*p*z));
	   thrust::tuple<double,double> EkKk = ellke(q);
	   const double n = 1./x1-1.;          
//	   const double n = 1./(p-z);  // from python version?!?
	   const double ellpic_bulrisch_n_q = ellpic_bulirsch(n,q);
#endif
	   const double x3 = p*p-z*z;
	   lambdad = 1./(9.*M_PI)*rsqrt(p*z)*
	     ( ((1.-x2)*(2.*x2+x1-3.)-3.*x3*(x2-2.))*EkKk.get<1>()
	     +4.*p*z*(z*z+7.*p*p-4.)*EkKk.get<0>()
	     -3.*x3/x1*ellpic_bulrisch_n_q );
	   thrust::get<muo1_index>(val) = 1.-((1.-u1-2.*u2)*lambdae+(u1+2.*u2)*(lambdad+2./3.*(p > z))+u2*etad)/omega;
	   if(Uniform) thrust::get<mu0_index>(val)  =1.- lambdae;
//	   return; 
	   }
	 else if(p<1.) // case 3, 4, 9, 10 (planet completely inside star)
	   {
#if CPU_DEBUG
	   assert(z<1.-p); 
#endif
	     etad = 0.5*p*p*(p*p+2.*z*z);
	     lambdae = p*p;
	     if(z==1.-p) // case 4
	       {
	       lambdad = ( 6.*acos(1.-2.*p)-4.*sqrt(p*(1.-p))*(3.+2.*p-8.*p*p) )/(9.*M_PI);
	       if(p>0.5)
	        lambdad -= 2./3.;
	       thrust::get<muo1_index>(val) = 1.-((1.-u1-2.*u2)*lambdae+(u1+2.*u2)*(lambdad+2./3.*(p > z))+u2*etad)/omega;
	       if(Uniform) thrust::get<mu0_index>(val)  = 1.-lambdae;
//	       return;
	       }
	     else if(z==0.) // case 10
	       {
	       lambdad = -2./3.*(1.-p*p)*sqrt(1.-p*p);
	       thrust::get<muo1_index>(val) = 1.-((1.-u1-2.*u2)*lambdae+(u1+2.*u2)*(lambdad+2./3.*(p > z))+u2*etad)/omega;
	       if(Uniform) thrust::get<mu0_index>(val)  = 1.-lambdae;
//	       return;
	       }
	     else  // case 3, 9
	       {
#if !GROUP_FUNC_CALLS
	       double q = rsqrt((1.-x1)/(x2-x1));
	       thrust::tuple<double,double> EkKk = ellke(q);	   
	       double n = x2/x1-1.;
	       double ellpic_bulrisch_n_q = ellpic_bulirsch(n,q);
#endif
	       double x3 = p*p-z*z;
	       lambdad = 2./(9.*M_PI)*rsqrt(1.-x1)*
                       ( (1.-5.*z*z+p*p+x3*x3)*EkKk.get<1>()
		         +(1.-x1)*(z*z+7.*p*p-4.)*EkKk.get<0>()
			 -3.*x3/x1*ellpic_bulirsch(n,q) );
	       thrust::get<muo1_index>(val) = 1.-((1.-u1-2.*u2)*lambdae+(u1+2.*u2)*(lambdad+2./3.*(p > z))+u2*etad)/omega;
	       if(Uniform) thrust::get<mu0_index>(val)  = 1.-lambdae;
//	       return;			    
	       }
	     }  // end if (p<1.) case 3,4,9,10
	   } // end else case partially occulted

	double tmp = ((1.-u1-2.*u2)*lambdae+(u1+2.*u2)*(lambdad+2./3.*(p > z))+u2*etad)/omega;
        thrust::get<muo1_index>(val) = 1.+ (1.-2.*(p0>0.)) * tmp;
        if(Uniform) thrust::get<mu0_index>(val) = 1.+ (1.-2.*(p0>0.)) * lambdae;
        return;

	}
};


	template<bool Uniform>
	void occultquad_wrapper_c(const double *ph_z, const double *ph_u1, const double *ph_u2, const double *ph_p, const int num, double *ph_muo1, double *ph_mu1)
	  {

	    int gpuid = ebf_cuda::init_cuda();
	    // put vectors in thrust format from raw points
	    thrust::host_vector<double> h_z(ph_z,ph_z+num);
	    thrust::host_vector<double> h_u1(ph_u1,ph_u1+num);
	    thrust::host_vector<double> h_u2(ph_u2,ph_u2+num);
	    thrust::host_vector<double> h_p(ph_p,ph_p+num);

	    cutCreateTimer(&memoryTime);  cutCreateTimer(&kernelComputeTime);	cutCreateTimer(&kernelSortTime);
	    cutResetTimer(memoryTime);    cutResetTimer(kernelComputeTime);	cutResetTimer(kernelSortTime);


	    if(gpuid>=0)
	    	{
		// allocate mem on GPU
		thrust::device_vector<double> d_z(num);
		thrust::device_vector<double> d_u1(num);
		thrust::device_vector<double> d_u2(num);
		thrust::device_vector<double> d_p(num);
		thrust::device_vector<double> d_muo1(num);
		thrust::device_vector<double> d_mu1(num);
		cudaThreadSynchronize();

		cutStartTimer(memoryTime);
		// transfer input params to GPU
		d_z = h_z;
		d_u1 = h_u1;
		d_u2 = h_u2;
		d_p = h_p;
		cudaThreadSynchronize();
		cutStopTimer(memoryTime);

		// distribute the computation to the GPU
		cutStartTimer(kernelComputeTime);

		thrust::for_each(
	   	   thrust::make_zip_iterator(thrust::make_tuple(d_z.begin(),d_u1.begin(),d_u2.begin(),d_p.begin(), d_muo1.begin(),d_mu1.begin() )),
	   	   thrust::make_zip_iterator(thrust::make_tuple(d_z.end(),  d_u1.end(),  d_u2.end(),  d_p.end(),   d_muo1.end(),  d_mu1.end()   )), 
		   occultquad_functor<Uniform>() );

		 cudaThreadSynchronize();
		 cutStopTimer(kernelComputeTime);

		 // transfer results back to host
		 cutStartTimer(memoryTime);
		 thrust::copy(d_muo1.begin(),d_muo1.end(),ph_muo1);
		 if(Uniform) thrust::copy(d_mu1.begin(), d_mu1.end(), ph_mu1);
		 cudaThreadSynchronize();
		 cutStopTimer(memoryTime);
		 }
	       else
		 {
		 // distribute the computation to the CPU
		 cutStartTimer(kernelComputeTime);

		 thrust::for_each(
		    	   	   thrust::make_zip_iterator(thrust::make_tuple(h_z.begin(),h_u1.begin(),h_u2.begin(),h_p.begin(),ph_muo1,ph_mu1)),
				   thrust::make_zip_iterator(thrust::make_tuple(h_z.end(),  h_u1.end(),  h_u2.end(),  h_p.end(),ph_muo1+num,ph_mu1+num)), 
				   occultquad_functor<Uniform>() );
		  cutStopTimer(kernelComputeTime);	
		  }
	}

} // end namespace limbdarkening


int main(int argc, char **argv)
{
	int num_zs = 8196;
	int num_planet_sizes = 1024;
	double max_planet_size = 0.1;
	verbose = 0;
	   { // read parameters from command line
	   std::istringstream iss;
	   if(argc>1)
	     {
	     iss.str(std::string (argv[1]));
	     iss >> num_zs;
	     iss.clear();
	     }
	   if(argc>2)
	     {
	     iss.str(std::string (argv[2]));
	     iss >> num_planet_sizes;
	     iss.clear();
	     }
	   if(argc>3)
	     {
	     iss.str(std::string (argv[3]));
	     iss >> max_planet_size;
	     iss.clear();
	     }
	   if(argc>4)
	     {
	     iss.str(std::string (argv[4]));
	     iss >> verbose;
	     iss.clear();
	     }
	   }
	int num_eval = num_planet_sizes*num_zs;  
	std::cerr << "# " << argv[0] << " nzs= " << num_zs << " nps= " << num_planet_sizes << " max_planet_size= " << max_planet_size << " verbose= " << verbose << "\n";

	// allocate host memory
	thrust::host_vector<double> h_z(num_eval);
	thrust::host_vector<double> h_u1(num_eval);
	thrust::host_vector<double> h_u2(num_eval);
	thrust::host_vector<double> h_p(num_eval);
	thrust::host_vector<double> h_muo1(num_eval);
	thrust::host_vector<double> h_mu0(num_eval);

	// initialize data on host 
	for(int i=0;i<num_planet_sizes;++i)
	  {
	  for(int j=0;j<num_zs;++j)
	    {	
	    int k = i*num_zs+j;
	    if(verbose>=256)
	       h_z[k] = 2.0*rand()/RAND_MAX;
	    else
	       h_z[k] = 2.0*static_cast<double>(j)/static_cast<double>(num_zs);


	    h_u1[k] = 0.1;
	    h_u2[k] = 0.3;
	    h_p[k] = max_planet_size*static_cast<double>(i+1)/static_cast<double>(num_planet_sizes);
	    }
	  }

	// optional check up on input values
	if(verbose%128>4) 
	   {
	   for(int i = 0; i < num_eval; i++)
              std::cout << " i= " << i << "z= " << h_z[i] << " u1= " << h_u1[i] << " u2= " << h_u2[i] << " p= " << h_p[i] << std::endl;
	   }

	// extract raw pointers to host memory to simulate what you'd get from IDL or another library
	double *ph_z = &h_z[0];
	double *ph_u1 = &h_u1[0];
	double *ph_u2 = &h_u2[0];
	double *ph_p  = &h_p[0];
	double *ph_muo1 = &h_muo1[0];
	double *ph_mu0 = &h_mu0[0];

	// wrapper function that could be called from IDL
	if(verbose%256>=128) // testing whether merging function calls helps
	   limbdarkening::occultquad_wrapper_c<true>(ph_z,ph_u1,ph_u2,ph_p,num_eval,ph_muo1,ph_mu0);
	else
	   limbdarkening::occultquad_wrapper_c<false>(ph_z,ph_u1,ph_u2,ph_p,num_eval,ph_muo1,ph_mu0);

	 // print results
	 if(verbose%128>0 ) 
	    {
	    for(int i = 0; i < num_eval; i++)
		{
		 std::cout << "i= " << i << " z= " << h_z[i] << " p= " << h_p[i] << " muo1= " << ph_muo1[i];
		 if(verbose>=128)
		    std::cout << " mu1= " << ph_mu0[i];
		 std::cout << std::endl;
		}
            }
	
	// report time spent on calculations and memory transfer
	std::cerr << "# Time for compute kernel: " << cutGetTimerValue(kernelComputeTime) << " ms, Time for sort kernels: " << cutGetTimerValue(kernelSortTime) << " ms, Time for memory: " << cutGetTimerValue(memoryTime) << " ms, Total time: " << cutGetTimerValue(kernelComputeTime)+cutGetTimerValue(kernelSortTime)+cutGetTimerValue(memoryTime) << " ms \n"; 
	return 0;
}



