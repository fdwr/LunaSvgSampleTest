/*
 * @(#)CCGL.java  2/16/04
 *
 * Copyright (c) 2004, Michael Cross All Rights Reserved.
 *
 * Time stepper for lattice of Complex Ginzburg Landau oscillators
 */

import java.util.*;

public class CCGL extends CODE {
      private double c3,D,square;
      private int i,j,k;     
      
      
      // Consructor
      public CCGL() {
      
            // Number of fields
            fields=2;
            numPlotTypes=2;
            spectral=false; 
            
            // Parameters of equation
            nParameters=2;
            defaultValues=new String[nParameters];
            defaultValues[0]="1.25";
            defaultValues[1]="1";
            labels = new String[nParameters];
            labels[0]=" c3 ";             
            labels[1]=" D ";
      }     

     // Grab parameters for equation
     public void setParameters(int nParameters, double[] in_parameters) {            
            super.setParameters(nParameters, in_parameters);
            c3=parameters[0];
            D=parameters[1];
     }
         
     public void derivs(double[][][] psi, double[][][] dpsi, double t, int nx, int ny, int fields){

           for(i=1;i<=nx;i++) {
             for(j=1;j<=ny;j++) {        
               square = Math.pow(psi[0][i][j],2)+Math.pow(psi[1][i][j],2);
               dpsi[0][i][j] = (1.0-square)*psi[0][i][j]+(1.0-square)*c3*psi[1][i][j]
                            +D*(psi[0][i-1][j]+psi[0][i+1][j]+psi[0][i][j-1]+psi[0][i][j+1]
                                -4*psi[0][i][j]);
               dpsi[1][i][j] = (1.0-square)*psi[1][i][j]-(1.0-square)*c3*psi[0][i][j]
                            +D*(psi[1][i-1][j]+psi[1][i+1][j]+psi[1][i][j-1]+psi[1][i][j+1]
                                -4*psi[1][i][j]);               
               ;
          }
       }          
     
      }
    
          
     // Choose what to plot: return field to plot in psir[0]
     public void makePlot(double[][][] psir, int plotwidth, int plotheight) {

          int i,j,k;
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
