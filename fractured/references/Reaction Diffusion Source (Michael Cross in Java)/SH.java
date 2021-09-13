/*
 * @(#)SH.java  5/1/99
 *
 * Copyright (c) 1999, Michael Cross All Rights Reserved.
 *
 * Time stepper for Swift-Hohenberg Equation using pseudo-spectral method
 * NB: extends spectralPDE
 */

import java.util.*;

public class SH extends spectralPDE {
      private int i,j,k;     
      private double eps,g1;            // convenience notation for parameters of equation 
            
      // Consructor
      public SH() {
      
            // All the fields in the Constructor are REQUIRED
            fields=1;                   // Number of fields
            spectral=true;              // True if FFT plots may be shown (spectral)
            numPlotTypes=1;             // Number of plot types
      // Default plots of first field are made in makePlot and makeFFTPlot
      // methods in spectralPDE.java. These can be overwritten here for fancier
      // plots or plots of other fields.
            
            // Parameters of equation
            nParameters=2; 
            nInitialParameters=7; 
            defaultValues=new String[nParameters];
            defaultValues[0]="0.25";
            defaultValues[1]="0.";
            labels = new String[nParameters];
            labels[0]=" eps ";
            labels[1]="  g1 ";             
      }     

     // Grab parameters for equation
     public void setParameters(int nParameters, double[] in_parameters) {            
            super.setParameters(nParameters, in_parameters);
            eps=parameters[0];
            g1=parameters[1];
     }
     
     // Choose pallette for plot: choice may depend on integer plotType set in html file
     // Choices are grey, circ (circular rainbow) and RGB
     public void setPallette () {      
            myPal = new RGBPallette();
     }     

     // Construct multipliers of linear terms in transform equation at wavevector k
     protected double[] getArg(double k) {
        double[] d=new double[fields];
        d[0]=eps-Math.pow(k*k-1,2);
        return d;
    }
    
    // Form nonlinear term: take field psip[][][] and construct nonlinear terms psip[][][]
    protected void formNonlinearTerm() {
       int i,j;
       double p;
       
       // Nonlinearity -psi^3 + g1*psi^2
       for(j=1;j<=ny;j++) {
          for(i=1;i<=nx;i++) {
             psit[0][i][j] =- Math.pow(psip[0][i][j],3)+g1*Math.pow(psip[0][i][j],2);
          }
       }                    
    }
    
      // Set random initial conditions specified by icp[][]
           public void initialCondition(double[][][] psi, double[][] icp, int nicp) {
           double x,rx,ry,wx,wy,amp;           
           for(int k=0;k<fields;k++) { 
                wx=icp[k][2];
                wy=icp[k][3];
                amp=icp[k][4];  
                for(int i=1;i<=nx;i++) {
                    x=i*mesh;                       
                    rx=icp[k][5]*(Math.random()-0.5);
                    for(int j=1;j<=ny;j++) { 
                        ry=icp[k][6]*(Math.random()-0.5);                                                                      
                        psi[k][i][j]=amp*Math.cos(wx*x+wy*j*mesh+rx+ry)+
                            icp[k][0]*(Math.random()-0.5)+icp[k][1];
                    }                     
                }  
           }     
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
               
}
