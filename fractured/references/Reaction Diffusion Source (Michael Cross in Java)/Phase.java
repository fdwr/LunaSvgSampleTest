/*
 * @(#)Phase.java  2/16/04
 *
 * Copyright (c) 2004, Michael Cross All Rights Reserved.
 *
 * Time stepper for lattice of phase oscillators
 */

import java.util.*;

public class Phase extends CODE {
      private double b,w;
      private int i,j,k;
      private double[][] om; 
      private static final double Pi2=2*Math.PI;   
      
      
      // Consructor
      public Phase() {
      
            // Number of fields
            fields=1;
            numPlotTypes=1;
            spectral=false; 
            nInitialParameters=0;   
            
            // Parameters of equation
            nParameters=2;
            defaultValues=new String[nParameters];
            defaultValues[0]="1";
            defaultValues[1]="1";
            labels = new String[nParameters];
            labels[0]="  K  ";        // alpha 
            labels[1]=" w ";
      }
      
      public void init(int width, int height, double[] in_parameters, double in_dt,
                  int in_plotType) {
                  
            super.init(width, height, in_parameters, in_dt, in_plotType);
            w=in_parameters[1];
            om= new double[nx+2][ny+2];              
    }             
            
                       

     // Grab parameters for equation
     public void setParameters(int nParameters, double[] in_parameters) {            
            super.setParameters(nParameters, in_parameters);
            b=in_parameters[0]/4;
            w=in_parameters[1];
     }
         
     public void derivs(double[][][] psi, double[][][] dpsi, double t, int nx, int ny, int fields){

           for(i=1;i<=nx;i++)
             for(j=1;j<=ny;j++)        
               dpsi[0][i][j] = om[i][j] +
                            b*(Math.sin(psi[0][i-1][j]-psi[0][i][j])
                             + Math.sin(psi[0][i+1][j]-psi[0][i][j])
                             + Math.sin(psi[0][i][j-1]-psi[0][i][j])
                             + Math.sin(psi[0][i][j+1]-psi[0][i][j]));
      }
      
      public void initialCondition(double[][][] psi, double[][] icp, int nicp) {
        for(i=1;i<=nx;i++) {
           for(j=1;j<=ny;j++) {
                om[i][j]=w*(Math.random()-0.5);
                psi[0][i][j]=Pi2*Math.random();
           }
        }
      }             
    
          
     // Choose what to plot: return field to plot in psir[0]
     public void makePlot(double[][][] psir, int plotwidth, int plotheight) {  
        for(i=1;i<=nx;i++) {
           for(j=1;j<=ny;j++) {
                psir[0][i][j]=mod(psir[0][i][j],Pi2);
           }
        }                 
     }

     private double mod(double x, double shift) {
         while (x>shift) {
            x=x-shift;
         }   
         while (x<0.) {
            x=x+shift;
         }
         return x;
      }     
     
     // Choose pallette for plot based on integer plotType set in html file
     // Choices are grey, circ (circular rainbow) and RGB
     public void setPallette() {      
        myPal = new circPallette();
     }
     
}
