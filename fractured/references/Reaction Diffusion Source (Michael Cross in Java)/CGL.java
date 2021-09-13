/*
 * @(#)CGL.java  1.5 98/11/5
 *
 * Copyright (c) 1998, Michael Cross All Rights Reserved.
 *
 * Time stepper for Complex Ginzburg Landau Equation using pseudo-spectral method
 */

import java.util.*;

public class CGL extends spectralPDE {
      private double d1;
      private int i,j,k;     
      
      
      // Consructor
      public CGL() {
      
            // Number of fields
            fields=2;
            numPlotTypes=2;
            spectral=false; 
            
            // Parameters of equation
            nParameters=1;
            defaultValues=new String[1];
            defaultValues[0]="1.25";
            labels = new String[1];
            labels[0]=" c3 ";             
      }     

     // Grab parameters for equation
     public void setParameters(int nParameters, double[] in_parameters) {            
            super.setParameters(nParameters, in_parameters);
            d1=parameters[0];
     }
     
     // Construct multipliers of linear terms in transform equation at wavevector k
      protected double[] getArg(double k) {
        double[] d=new double[fields];
        d[0]=1-k*k;
        d[1]=1-k*k;
        return d;
    }
    
    // Form nonlinear term: take field psip[][][] and construct nonlinear terms psip[][][]
     protected void formNonlinearTerm() {
       int i,j;
       double square;
       
       for(j=1;j<=ny;j++) {
          for(i=1;i<=nx;i++) {
             square = Math.pow(psip[0][i][j],2)+Math.pow(psip[1][i][j],2);
             psit[0][i][j] = -square*psip[0][i][j]+(1.0-square)*d1*psip[1][i][j];
             psit[1][i][j] = -square*psip[1][i][j]-(1.0-square)*d1*psip[0][i][j];
          }
       }                    
    }        
          
     // Choose what to plot: return field to plot in psir[0]
     public void makePlot(double[][][] psir, int plotwidth, int plotheight) {

          int i,j,k;
          for(k=0;k<fields;k++) {
            // Zero out zone boundary values      
              for(i=1;i<=plotwidth;i++)
                    psir[k][i][2]=0.;

              for(j=1;j<=plotheight;j++)    
                    psir[k][2][j]=0.;

              // Transform to real space and form plot quantities
              myFFT.trbak(psir[k],plotwidth,plotheight);
          }
          for(j=1;j<=plotheight;j++) {
             for(i=1;i<=plotwidth;i++) {
                if(plotType==0) 
                   psir[0][i][j] = Math.sqrt(Math.pow(psir[0][i][j],2)+Math.pow(psir[1][i][j],2));
                else  
                   psir[0][i][j] = Math.atan2(psir[1][i][j],psir[0][i][j]);
             }
          }                  
     }

     
     
     // Choose pallette for plot based on integer plotType set in html file
     // Choices are grey, circ (circular rainbow) and RGB
     public void setPallette() {      
            if(plotType==0) 
                  myPal = new greyPallette();
            else
                  myPal = new circPallette();
     }
     
}
