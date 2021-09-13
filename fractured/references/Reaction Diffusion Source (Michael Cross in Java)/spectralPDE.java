/*
 * @(#spectralPDE.java  5/1/99
 *
 * Copyright (c) 1999, Michael Cross All Rights Reserved.
 *
 * Stub code for specral time stepper for PDE 
 */

import java.util.*;

public class spectralPDE extends PDE {

      protected double[][][] psit,psip,psinl;
      protected double[][] rmodk;
      protected double[] arg;      

      protected FFT2D myFFT;
            
      public void init(int width, int height, double[] in_parameters, double in_dt,
                  double mesh, int in_plotType) {
                  
            // Most intialization done in PDE.class
            super.init(width, height, in_parameters, in_dt, mesh, in_plotType);
                        
            psit = new double[fields][nx+1][ny+1]; 
            psip = new double[fields][nx+1][ny+1];
            psinl = new double[fields][nx+1][ny+1];
            
            arg=new double[fields];
            
            myFFT=new FFT2D();
            init_k(nx,ny,mesh);                                    
      }     
      
      // Set random initial conditions specified by icp[][]
      // Can override for other i.c. if desired
      public void initialCondition(double[][][] psi, double[][] icp, int nicp) {

          for(int j=1;j<=ny;j++)
            for(int i=1;i<=nx;i++)
                for(int k=0;k<fields;k++)
                   psi[k][i][j]=icp[k][0]*(Math.random()-0.5)+icp[k][1];
          // Zero out zone boundary values      
/*          for(int k=0;k<fields;k++) {
              for(int i=1;i<=nx;i++)
                    psi[k][i][2]=0.;

              for(int j=1;j<=ny;j++)    
                    psi[k][2][j]=0.;
          }         
*/          
          for(int k=0;k<fields;k++)
                myFFT.trfor(psi[k],nx,ny);
                   
      }                               


      // Default time stepper. Assumes linear terms are diagonal with k dependent
      // codfficients specified by getArg() in function class
      public double tstep(double[][][] psi, double t) {
            double rmk,efac,oadt,adt;
            double c1=0;
            double c2=0;
            double tp;
            int i,j,k;     
            
     
//    method based on implicit integration 
//    of linear fourier modes
    
//    compute nonlinear contribution to time derivative
     
            tderiv(psi);
     
//    save the nonlinear term for the corrector
     
//            for(j = 1;j<=ny;j++)
//               for(i = 1;i<=nx;i++)
//                  for(k=0;k<fields;k++)
//                    psinl[k][i][j] = psit[k][i][j];

            for(k=0;k<fields;k++)
                for(i = 1;i<=nx;i++)
                    System.arraycopy(psit[k][i],1,psinl[k][i],1,ny);
                    
            for(j = 1;j<=ny;j++) {
               for(i=1;i<=nx;i++) {
                  rmk = rmodk[i][j];
                  arg=getArg(rmk);
                  for(k=0;k<fields;k++) {
                      efac = Math.exp(arg[k]*dt);
                      psi[k][i][j] = efac*psi[k][i][j] + psit[k][i][j]/arg[k]*(efac-1.0);
                  }    
               }
            }

            tp = t + dt;
            tderiv(psi);

            for(j=1;j<=ny;j++) {
               for(i=1;i<=nx;i++) {
                  rmk = rmodk[i][j];
                  arg = getArg(rmk);
                  for(k=0;k<fields;k++) {
                      adt = arg[k]*dt;
                      oadt = 1.0/adt;
                      efac = Math.exp(adt);
                      c1 = psinl[k][i][j];
                      c2 = psit[k][i][j]-c1;
                      psi[k][i][j] = psi[k][i][j] + dt*c2*oadt*(efac*oadt - oadt - 1.0);                      
                    }
               }
            }
            t = t + dt;
            return t;
      }

      //Dummy routine for coefficients of linear terms (assumed diagonal)
      protected double[] getArg(double k) {
          double[] d=new double[fields];
          return d;
      }               
            
      // Default routine for computing nonlinear term.
      // Assumes only dependence of psi (not derivatives) specified by formNonlinearTerm
      // in function class (psip->psit)    
      protected void tderiv (double[][][] psi) {
            
            int i,j,k;
            // Make Fourier space copy psip and invert
            
            for(k=0;k<fields;k++) {
                for(i=1;i<=nx;i++) {
//                 for(j=1;j<=ny;j++) {
//                    psip[k][i][j] = psi[k][i][j];                    
//                 }
                   System.arraycopy(psi[k][i],1,psip[k][i],1,ny);
                }
                myFFT.trbak (psip[k],nx,ny);                
            }
            // Get nonlinear term for specific equation
            formNonlinearTerm();

            // Return result to Fourier space
            for(k=0;k<fields;k++)
                myFFT.trfor(psit[k],nx,ny);

//          dealias the result (not implemented)
//          dealias(nx,ny,3,psit);

            return;
     }
     
     // Dummy routine to be over-ridden by specific equations
     protected void formNonlinearTerm() {};
          
     // Forms plot from first field.
     // May be overridden with plot depending in plotType
//     public void makePlot(double[][][] psir, int plotwidth, int plotheight) {
//          int i,j,k;
//          for(k=0;k<fields;k++) {
              // Zero out zone boundary values      
//              for(i=1;i<=plotwidth;i++)
//                    psir[k][i][2]=0.;
//
//              for(j=1;j<=plotheight;j++)    
//                    psir[k][2][j]=0.;
//
              // Transform to real space and form plot quantities
//              myFFT.trbak(psir[k],plotwidth,plotheight);
//          }
//     }
     public void makePlot(double[][][] psir, int plotwidth, int plotheight) {
          int i,j,k;
              k=0;
              if(plotType!=0 & plotType < fields) k=plotType;
              if(k != 0) {
                for(j=1;j<=plotheight;j++) {
                    for(i=1;i<=plotwidth;i++) {
                        psir[0][i][j] = psir[k][i][j];
                    }
                }
              }              
              // Zero out zone boundary values      
              for(i=1;i<=plotwidth;i++)
                    psir[0][i][2]=0.;

              for(j=1;j<=plotheight;j++)    
                    psir[0][2][j]=0.;

              // Transform to real space and form plot quantities
              myFFT.trbak(psir[0],plotwidth,plotheight);
     }
     
     // Forms FFT plot of first of fields
     // May be overridden with plot depending in plotType
     public void makeFFTPlot(double[][][] psir, int plotwidth, int plotheight) {
          int i,j,k;
          int i1,j1,ix,iy;
          double[][] temp=new double[plotwidth+1][plotheight+1];
              k=0;
              if(plotType!=0 & plotType < fields) k=plotType;          
              // Zero out zone boundary values      
              for(i=1;i<=plotwidth;i++)
                    psir[k][i][2]=0.;    

              for(j=1;j<=plotheight;j++) {
                    psir[k][2][j]=0.;
              }
                                    
          for(i=1;i<=plotwidth;i++)
            for(j=1;j<=plotheight;j++)
                  temp[i][j]=0.;


          for(i=1;i<=plotwidth/2;i++) {
//            System.out.println("There is a IBM JIT bug here");              
              for(j=1;j<=plotheight/2;j++) {                  
                  temp[plotwidth/2+i-1][plotheight/2+j-1]=                                                               
                                Math.pow(psir[k][2*i-1][2*j-1]-psir[k][2*i][2*j],2)
                              + Math.pow(psir[k][2*i-1][2*j]+psir[k][2*i][2*j-1],2);
                  temp[plotwidth/2-i+1][plotheight/2-j+1]=
                                temp[plotwidth/2+i-1][plotheight/2+j-1];
                  temp[plotwidth/2-i+1][plotheight/2+j-1]=   
                              + Math.pow(psir[k][2*i-1][2*j-1]+psir[k][2*i][2*j],2)
                              + Math.pow(psir[k][2*i-1][2*j]-psir[k][2*i][2*j-1],2);
                  temp[plotwidth/2+i-1][plotheight/2-j+1]=
                                temp[plotwidth/2-i+1][plotheight/2+j-1];
              }
          }

                              
          for(i=0,i1=0;i<plotwidth/(2*scalex);i++) {
              for(ix=0;ix<scalex;ix++,i1++) {
                for(j=0,j1=0;j<plotheight/(2*scaley);j++) {
                  for(iy=0;iy<scaley;iy++,j1++) {
                        psir[0][plotwidth/2+i1][plotheight/2+j1]=
                            Math.sqrt(temp[plotwidth/2+i][plotheight/2+j]);                              
                        psir[0][plotwidth/2-i1][plotheight/2+j1]=
                            Math.sqrt(temp[plotwidth/2-i][plotheight/2+j]);                              
                        psir[0][plotwidth/2+i1][plotheight/2-j1]=
                            Math.sqrt(temp[plotwidth/2+i][plotheight/2-j]);                              
                        psir[0][plotwidth/2-i1][plotheight/2-j1]=
                            Math.sqrt(temp[plotwidth/2-i][plotheight/2-j]);                              
                  }
                }
              }
           }
                      
     }                 
          
//    Set up complicated array of mod k for efficiency
      private void init_k(int nx, int ny, double mesh) {
      
          double alpha = 2.0*Math.PI/(nx*mesh);
          double beta = 2.0*Math.PI/(ny*mesh);
          double kx,ky;
          int i,j,k;
          rmodk = new double[nx+1][ny+1];
     
          for(j=1;j<=ny;j++) {
             ky = (j-1)/2;
             if ( j==1) ky = 0;
             if ( j== 2) ky = ny/2;
             for(i=1;i<=nx;i++) {
                kx = (i-1)/2;
                if ( i== 1) kx = 0;
                if ( i== 2) kx = nx/2;
                rmodk[i][j] = Math.sqrt(Math.pow(alpha*kx,2) + Math.pow(beta*ky,2));
             }
          }
      }                      
}
