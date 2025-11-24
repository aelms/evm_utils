#include <time.h>
#include <error.h>
#include <svdpi.h>
#include <iostream>

using namespace std;

extern "C" long int ut_wallclock_ns() {
   struct timespec tv;
   if(clock_gettime(CLOCK_REALTIME, &tv) != 0) {
      error(0,0,"clock_gettime failed\n");
   }
   return ( tv.tv_sec * 1000000000 + tv.tv_nsec );
}