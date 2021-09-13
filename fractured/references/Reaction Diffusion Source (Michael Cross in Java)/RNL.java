/*
 * @(#)RNL.java  2/16/04
 *
 * Copyright (c) 2004, Michael Cross All Rights Reserved.
 *
 * Time stepper for lattice of Complex Ginzburg Landau oscillators
 */

import java.util.*;

public class RNL extends CODE {
      private double a,b,w,square;
      private int i,j,k;
      private double[][] om;    
      
      
      // Consructor
      public RNL() {
      
            // Number of fields
            fields=2;
            numPlotTypes=2;
            spectral=false;    
            
            // Parameters of equation
            nParameters=3;
            defaultValues=new String[nParameters];
            defaultValues[0]="1.25";
            defaultValues[1]="1";
            defaultValues[2]="1";
            labels = new String[nParameters];
            labels[0]="  "+"\u03B1"+"  ";        // alpha 
            labels[1]="  "+"\u03B2"+"  ";       // beta 
            labels[2]=" w ";
      }
      
      public void init(int width, int height, double[] in_parameters, double in_dt,
                  int in_plotType) {
                  
            super.init(width, height, in_parameters, in_dt, in_plotType);
            w=parameters[2];
            om= new double[nx+2][ny+2];              
    }             
            
                       

     // Grab parameters for equation
     public void setParameters(int nParameters, double[] in_parameters) {            
            super.setParameters(nParameters, in_parameters);
            a=parameters[0];
            b=parameters[1]/4;
            w=parameters[2];
     }
         
     public void derivs(double[][][] psi, double[][][] dpsi, double t, int nx, int ny, int fields){

           for(i=1;i<=nx;i++) {
             for(j=1;j<=ny;j++) {        
               square = Math.pow(psi[0][i][j],2)+Math.pow(psi[1][i][j],2);
               dpsi[0][i][j] = (1.0-square)*psi[0][i][j]-(om[i][j]+a-a*square)*psi[1][i][j]
                            -b*(psi[1][i-1][j]+psi[1][i+1][j]+psi[1][i][j-1]+psi[1][i][j+1]
                                -4*psi[1][i][j]);
               dpsi[1][i][j] = (1.0-square)*psi[1][i][j]+(om[i][j]+a-a*square)*psi[0][i][j]
                            +b*(psi[0][i-1][j]+psi[0][i+1][j]+psi[0][i][j-1]+psi[0][i][j+1]
                                -4*psi[0][i][j]);               
          }
       }          
     
      }
      
      public void initialCondition(double[][][] psi, double[][] icp, int nicp) {
        super.initialCondition(psi, icp, nicp);
        for(i=1;i<=nx;i++)
           for(j=1;j<=ny;j++)
                om[i][j]=w*(Math.random()-0.5);
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
