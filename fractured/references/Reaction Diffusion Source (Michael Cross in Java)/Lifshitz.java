/*
 * @(#)SH.java  5/1/99
 *
 * Copyright (c) 1999, Michael Cross All Rights Reserved.
 *
 * Time stepper for Lifshitz-Petrich modification of theSwift-Hohenberg Equation
 * using pseudo-spectral method
 * NB: extends spectralPDE
 */

import java.util.*;

public class Lifshitz extends spectralPDE {
      private int i,j,k;     
      private double eps,g1,q1;            // convenience notation for parameters of equation 
            
      // Consructor
      public Lifshitz() {
      
            // All the fields in the Constructor are REQUIRED
            fields=1;                   // Number of fields
            spectral=true;              // True if FFT plots may be shown (spectral)
            numPlotTypes=1;             // Number of plot types
      // Default plots of first field are made in makePlot and makeFFTPlot
      // methods in spectralPDE.java. These can be overwritten here for fancier
      // plots or plots of other fields.
            
            // Parameters of equation
            nParameters=3;
            defaultValues=new String[nParameters];
            defaultValues[0]="0.";
            defaultValues[1]="1.";
            defaultValues[2]="1.9318";
            labels = new String[nParameters];
            labels[0]=" eps ";
            labels[1]="alpha";
            labels[2]="  q  ";             
      }     

     // Grab parameters for equation
     public void setParameters(int nParameters, double[] in_parameters) {            
            super.setParameters(nParameters, in_parameters);
            eps=parameters[0];
            g1=parameters[1];
            q1=parameters[2];
     }
     
     // Choose pallette for plot: choice may depend on integer plotType set in html file
     // Choices are grey, circ (circular rainbow) and RGB
     public void setPallette () {      
            myPal = new RGBPallette();
     }     

     // Construct multipliers of linear terms in transform equation at wavevector k
     protected double[] getArg(double k) {
        double[] d=new double[fields];
        d[0]=eps-Math.pow(k*k-1,2)*Math.pow(k*k-q1*q1,2);
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
               
}
