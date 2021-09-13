/*
 * @(#)Brusselator.java  1.5 98/11/5
 *
 * Copyright (c) 1998, Michael Cross All Rights Reserved.
 *
 * Time stepper for Complex Ginzburg Landau Equation using pseudo-spectral method
 */

import java.util.*;

public class Brusselator extends spectralPDE {
      private double a,b,d1,d2;
      private int i,j;
      
      // Consructor
      public Brusselator() {
            spectral=false;
            numPlotTypes=2;
            nParameters=4;
            defaultValues=new String[nParameters];
            defaultValues[0]="2.";
            defaultValues[1]="5.";
            defaultValues[2]="1.";
            defaultValues[3]="4.";
            labels = new String[nParameters];
            labels[0]=" a ";   
            labels[1]=" b ";                  
            labels[2]=" d1";   
            labels[3]=" d2";
            fields=2;               
      }     
   
     public void setParameters(int nParameters, double[] parameter) {            
            super.setParameters(nParameters, parameters);
            a=parameter[0];
            b=parameter[1];
            d1=parameter[2];
            d2=parameter[3];
     }
          
     // Forms plot from two fields depending on plotType
//     public void makePlot(double[][][] psir, int plotwidth, int plotheight) {
//          
//          super.makePlot(psir, plotwidth, plotheight);          
//          if(plotType==1) {
//             for(j=1;j<=plotheight;j++) {
//                  for(i=1;i<=plotwidth;i++) {
//                     psir[0][i][j] = psir[1][i][j];
//                  }
//             }
//          }                    
//     }
     
     
     public void setPallette() {      
                  myPal = new greyPallette();
     }
     
     protected double[] getArg(double k) {
        double[] d=new double[fields];
        d[0]=(b-1.0) - d1*k*k;
        d[1]= -a*a - d2*k*k;
        return d;
    }
    
     protected void formNonlinearTerm() {
         int i,j;
         double square;
         for(j=1;j<=ny;j++) {
            for(i=1;i<=nx;i++) {
                square = (b/a)*Math.pow(psip[0][i][j],2)+2.*a*psip[0][i][j]*psip[1][i][j]
                     + Math.pow(psip[0][i][j],2)*psip[1][i][j];
                psit[0][i][j] = square + a*a*psip[1][i][j]; 
                psit[1][i][j] = -square - b*psip[0][i][j];
            }
         }
     }                                           
}
