import java.util.*;
/**                    
* Calculates 2d FFT
* Uses routines from Numerical Recipes 
* @version 1 November 1998
* @author Michael Cross
*/
 public class FFT2D {
 
      public void trfor(double[][] data, int nx, int ny) {
             realftx(data,nx,ny,1);
             realfty(data,nx,ny,1);
       
             double rnorm = 4./(double)(nx*ny);
             for(int j = 1;j<=ny;j++) {
                for(int i = 1;i<=nx;i++) {
                   data[i][j] = data[i][j]*rnorm;
                }
             }
      } 
      
      public void trbak(double[][] data, int nx, int ny) {
             realftx(data,nx,ny,-1);
             realfty(data,nx,ny,-1);
       
      }             
      
//**********************************************************************      
/**
* FFT from Numerical recipes modified to do x transform for 2d FFT.
* @param data array of nx x ny data points<br>
* On return contains transform <br>
* For packing see Numerical Recipes
* @param    nx number of data points in x direction
* @param    ny number of data points in y direction
* @param    isign 1 for forward; -1 for inverse
*/          
//**********************************************************************          
      
      private void four1x(double data[][], int nx, int ny, int isign) {
          int mmax,m,j,istep,i,k;
          double wtemp,wr,wpr,wpi,wi,theta;
          double tempr,tempi;
          double swap;
    
          j=1;
          for (i=1;i<nx;i+=2) {
                if (j > i) {
                   for(k=1;k<=ny;k++) {
                      swap=data[j][k];
                      data[j][k]=data[i][k];
                      data[i][k]=swap;
                      
                      swap=data[j+1][k];
                      data[j+1][k]=data[i+1][k];
                      data[i+1][k]=swap;
                   }                  
                }
                m=nx >> 1;
                while (m >= 2 && j > m) {
                      j -= m;
                      m >>= 1;
                }
                j += m;
          }
          mmax=2;
          while (nx > mmax) {
                istep=2*mmax;
                theta=isign*(6.28318530717959/mmax);
                wtemp=Math.sin(0.5*theta);
                wpr = -2.0*wtemp*wtemp;
                wpi=Math.sin(theta);
                wr=1.0;
                wi=0.0;
                for (m=1;m<mmax;m+=2) {
                      for (i=m;i<=nx;i+=istep) {
                            j=i+mmax;
                            for (k=1;k<=ny;k++) {
                                  tempr=wr*data[j][k]-wi*data[j+1][k];
                                  tempi=wr*data[j+1][k]+wi*data[j][k];
                                  data[j][k]=data[i][k]-tempr;
                                  data[j+1][k]=data[i+1][k]-tempi;
                                  data[i][k] += tempr;
                                  data[i+1][k] += tempi;
                            }     
                      }
                      wr=(wtemp=wr)*wpr-wi*wpi+wr;
                      wi=wi*wpr+wtemp*wpi+wi;
                }
                mmax=istep;
          }
     }

//**********************************************************************      
//**********************************************************************      
/**
* FFT from Numerical recipes modified to do y transform for 2d FFT
* @param data array of nx x ny data points<br>
* On return contains transform <br>
* For packing see Numerical Recipes
* @param    nx number of data poitns in x direction
* @param    ny number of data points in y direction
* @param    isign 1 for forward; -1 for inverse
*/          
//**********************************************************************          
      private void four1y(double data[][], int nx, int ny, int isign) {
          int mmax,m,j,istep,i,k;
          double wtemp,wr,wpr,wpi,wi,theta;
          double tempr,tempi;
          double swap;

          j=1;
          for (i=1;i<ny;i+=2) {
                if (j > i) {
                       for (k=1;k<=nx;k++) {
                          swap=data[k][j];
                          data[k][j]=data[k][i];
                          data[k][i]=swap;
                     
                          swap=data[k][j+1];
                          data[k][j+1]=data[k][i+1];
                          data[k][i+1]=swap;                  
                       }
                }
                m=ny >> 1;
                while (m >= 2 && j > m) {
                      j -= m;
                      m >>= 1;
                }
                j += m;
          }
          mmax=2;
          while (ny > mmax) {
                istep=2*mmax;
                theta=isign*(6.28318530717959/mmax);
                wtemp=Math.sin(0.5*theta);
                wpr = -2.0*wtemp*wtemp;
                wpi=Math.sin(theta);
                wr=1.0;
                wi=0.0;
                for (m=1;m<mmax;m+=2) {
                      for (i=m;i<=ny;i+=istep) {
                            j=i+mmax;
                            for (k=1;k<=nx;k++) {
                              tempr=wr*data[k][j]-wi*data[k][j+1];
                              tempi=wr*data[k][j+1]+wi*data[k][j];
                              data[k][j]=data[k][i]-tempr;
                              data[k][j+1]=data[k][i+1]-tempi;
                              data[k][i] += tempr;
                              data[k][i+1] += tempi;
                            }
                      }
                      wr=(wtemp=wr)*wpr-wi*wpi+wr;
                      wi=wi*wpr+wtemp*wpi+wi;
                }
                mmax=istep;
          }
     }
     
//**********************************************************************      
/**
* FFT from Numerical recipes
* @param data array of n x ny data points<br>
* On return contains transform <br>
* For packing see Numerical Recipes.
* Note: convention for nx is as in Numerical Recipes, not as in realftx.for
* @param    nx number of data points in x direction
* @param    ny number of data points in y direction
* @param    isign 1 for forward; -1 for inverse
*/          
//**********************************************************************          
     
      private void realftx(double data[][], int nx, int ny, int isign)   {
      
      int i,i1,i2,i3,i4,np3,k;
      double c1=0.5,c2,h1r,h1i,h2r,h2i;
      double wr,wi,wpr,wpi,wtemp,theta;

      theta=3.141592653589793/(double) (nx>>1);
      if (isign == 1) {
            c2 = -0.5;
            four1x(data,nx,ny,1);
      } else {
            c2=0.5;
            theta = -theta;
      }
      wtemp=Math.sin(0.5*theta);
      wpr = -2.0*wtemp*wtemp;
      wpi=Math.sin(theta);
      wr=1.0+wpr;
      wi=wpi;
      np3=nx+3;
      for (i=2;i<=(nx>>2);i++) {
            i4=1+(i3=np3-(i2=1+(i1=i+i-1)));
            for(k=1;k<=ny;k++) {
                  h1r=c1*(data[i1][k]+data[i3][k]);
                  h1i=c1*(data[i2][k]-data[i4][k]);
                  h2r = -c2*(data[i2][k]+data[i4][k]);
                  h2i=c2*(data[i1][k]-data[i3][k]);
                  data[i1][k]=h1r+wr*h2r-wi*h2i;
                  data[i2][k]=h1i+wr*h2i+wi*h2r;
                  data[i3][k]=h1r-wr*h2r+wi*h2i;
                  data[i4][k] = -h1i+wr*h2i+wi*h2r;
            }      
            wr=(wtemp=wr)*wpr-wi*wpi+wr;
            wi=wi*wpr+wtemp*wpi+wi;
      }
      if (isign == 1) {
            for(k=1;k<=ny;k++) {
                  data[1][k] = (h1r=data[1][k])+data[2][k];
                  data[2][k] = h1r-data[2][k];
            }
      } else {
            for(k=1;k<=ny;k++) {
                  data[1][k]=c1*((h1r=data[1][k])+data[2][k]);
                  data[2][k]=c1*(h1r-data[2][k]);
            }
            four1x(data,nx,ny,-1);
      }
 }
//**********************************************************************      
/**
* FFT from Numerical recipes
* @param data array of nx x n data points<br>
* On return contains transform <br>
* For packing see Numerical Recipes.
* Note: convention for ny is as in Numerical Recipes, not as in realftx.for
* @param    nx number of data points in x direction
* @param    ny number of data points in y direction
* @param    isign 1 for forward; -1 for inverse
*/          
//**********************************************************************          
      private void realfty(double data[][], int nx, int ny, int isign)   {
      
      int i,i1,i2,i3,i4,np3,k;
      double c1=0.5,c2,h1r,h1i,h2r,h2i;
      double wr,wi,wpr,wpi,wtemp,theta;

      theta=3.141592653589793/(double) (ny>>1);
      if (isign == 1) {
            c2 = -0.5;
            four1y(data,nx,ny,1);
      } else {
            c2=0.5;
            theta = -theta;
      }
      wtemp=Math.sin(0.5*theta);
      wpr = -2.0*wtemp*wtemp;
      wpi=Math.sin(theta);
      wr=1.0+wpr;
      wi=wpi;
      np3=ny+3;
      for (i=2;i<=(ny>>2);i++) {
            i4=1+(i3=np3-(i2=1+(i1=i+i-1)));
            for(k=1;k<=nx;k++) {
                  h1r=c1*(data[k][i1]+data[k][i3]);
                  h1i=c1*(data[k][i2]-data[k][i4]);
                  h2r = -c2*(data[k][i2]+data[k][i4]);
                  h2i=c2*(data[k][i1]-data[k][i3]);
                  data[k][i1]=h1r+wr*h2r-wi*h2i;
                  data[k][i2]=h1i+wr*h2i+wi*h2r;
                  data[k][i3]=h1r-wr*h2r+wi*h2i;
                  data[k][i4] = -h1i+wr*h2i+wi*h2r;
            }      
            wr=(wtemp=wr)*wpr-wi*wpi+wr;
            wi=wi*wpr+wtemp*wpi+wi;
      }
      if (isign == 1) {
            for(k=1;k<=nx;k++) {
                  data[k][1] = (h1r=data[k][1])+data[k][2];
                  data[k][2] = h1r-data[k][2];
            }
      } else {
            for(k=1;k<=nx;k++) {
                  data[k][1]=c1*((h1r=data[k][1])+data[k][2]);
                  data[k][2]=c1*(h1r-data[k][2]);
            }
            four1y(data,nx,ny,-1);
      }
}

}
          
