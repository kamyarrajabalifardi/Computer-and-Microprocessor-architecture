#include <iostream> 
#include <cstdlib>
#include <ctime>
#include <fstream>
#include <cmath>
using namespace std;
void printBinary(int n, int i, FILE *fptr) 
{ 
  
    // Prints the binary representation 
    // of a number n up to i-bits. 
    int k; 
    for (k = i - 1; k >= 0; k--) { 
  
        if ((n >> k) & 1) 
            fprintf(fptr , "1"); 
        else
            fprintf(fptr, "0"); 
    } 
} 
  
typedef union { 
  
    float f; 
    struct
    { 
  
        // Order is important. 
        // Here the members of the union data structure 
        // use the same memory (32 bits). 
        // The ordering is taken 
        // from the LSB to the MSB. 
        unsigned int mantissa : 23; 
        unsigned int exponent : 8; 
        unsigned int sign : 1; 
  
    } raw; 
} myfloat; 
  
// Function to convert real value 
// to IEEE foating point representation 
void printIEEE(myfloat var, FILE *fptr) 
{ 
	fprintf(fptr , "%d", var.raw.sign); 
    printBinary(var.raw.exponent, 8, fptr); 
    printBinary(var.raw.mantissa, 23, fptr); 
} 
  
// Driver Code 
int main() 
{ 
  
    // Instantiate the union 
    myfloat var; 
  int notests = 2000;
  float a,b,c;
  float range = 999999999;
  srand(time(NULL));
  
  
  FILE *fio;
  fio = fopen("testdiv.hex", "w");
  for (int i = 0 ; i < notests ; i++) {
	  a = static_cast <float> (pow(-1,rand()%2)) * static_cast <float> (rand()) / (static_cast <float> (RAND_MAX/range));
	  b = static_cast <float> (pow(-1,rand()%2)) * static_cast <float> (rand()) / (static_cast <float> (RAND_MAX/range));
      var.f = a;
	  printIEEE(var, fio);
	  fprintf(fio, " ");
	  var.f = b;
	  printIEEE(var, fio);
	  fprintf(fio, " ");
	  var.f = a / b;
	  printIEEE(var, fio);
	  fprintf(fio, "\n");
  }
    return 0; 
} 