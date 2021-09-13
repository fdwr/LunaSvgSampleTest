/*
 * @(#)SH2.java  7/30/01
 *
 * Copyright (c) 2001, Michael Cross All Rights Reserved.
 *
 * Time stepper for 2 coupled Swift-Hohenberg Equations
 * using pseudo-spectral method
 * NB: extends spectralPDE
 */

import java.util.*;

public class SH2 extends spectralPDE {
      private int i,j,k;     
      private double eps,D,q,c,g,d,v,gamma;            // convenience notation for parameters of equation 
            
      // Consructor
      public SH2() {
      
            // All the fields in the Constructor are REQUIRED
            fields=2;                   // Number of fields
            spectral=true;              // True if FFT plots may be shown (spectral)
            numPlotTypes=2;             // Number of plot types
      // Default plots of first field are made in makePlot and makeFFTPlot
      // methods in spectralPDE.java. These can be overwritten here for fancier
      // plots or plots of other fields.
            
            // Parameters of equation
            nParameters=8;
            defaultValues=new String[nParameters];
            defaultValues[0]="0.3";
            defaultValues[1]="0.";
            defaultValues[2]="1.";
            defaultValues[3]="1.";
            defaultValues[4]="1.";
            defaultValues[5]="1.";
            defaultValues[6]="0.";
            defaultValues[7]="0.";
            labels = new String[nParameters];
            labels[0]=" eps ";
            labels[1]="Delta";
            labels[2]="  q  ";
            labels[3]="  c  ";
            labels[4]="  g  ";
            labels[5]="delta";
            labels[6]="  v  ";
            labels[7]="gamma";
      }     

     // Grab parameters for equation
     public void setParameters(int nParameters, double[] in_parameters) {            
            super.setParameters(nParameters, in_parameters);
            eps=parameters[0];
            D=parameters[1];
            q=parameters[2];
            c=parameters[3];
            g=parameters[4];
            d=parameters[5];
            v=parameters[6];
            gamma=parameters[7];           
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
        d[1]=(eps-D)-Math.pow(k*k-q*q,2);
        return d;
    }
    
    // Form nonlinear term: take field psip[][][] and construct nonlinear terms psip[][][]
    protected void formNonlinearTerm() {
       int i,j;
       double p;
       
       // Nonlinearity 
       for(j=1;j<=ny;j++) {
          for(i=1;i<=nx;i++) {
             psit[0][i][j] =  - Math.pow(psip[0][i][j],3)-d*Math.pow(psip[1][i][j],2)*psip[0][i][j]
                                    + 2*gamma*psip[0][i][j]*psip[1][i][j];
             psit[1][i][j] =- g*Math.pow(psip[1][i][j],3)-d*Math.pow(psip[0][i][j],2)*psip[1][i][j]
                                    + v*Math.pow(psip[1][i][j],2)+gamma*Math.pow(psip[0][i][j],2);
          }
       }                    
    }
               
}
