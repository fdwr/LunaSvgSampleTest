/*
 * @(#)QUAD.java  2/16/04
 *
 * Copyright (c) 2004, Michael Cross All Rights Reserved.
 *
 * Time stepper for lattice of quadratic maps
 */

import java.util.*;

public class QUAD extends Lattice {
      private double a,D;
      private int i,j,k;     
      
      
      // Consructor
      public QUAD() {
      
            // Number of fields
            fields=1;
            numPlotTypes=1;
            spectral=false;
            nInitialParameters=1; 
            
            // Parameters of equation
            nParameters=2;
            defaultValues=new String[nParameters];
            defaultValues[0]="4";
            defaultValues[1]="1";
            labels = new String[nParameters];
            labels[0]=" a ";             
            labels[1]=" D ";
      }     

     // Grab parameters for equation
     public void setParameters(int nParameters, double[] in_parameters) {            
            super.setParameters(nParameters, in_parameters);
            a=parameters[0];
            D=parameters[1];
     }
     
      // Time stepper. 
      public double tstep(double[][][] psi, double t) {
                   
            for(i=0;i<fields;i++)
              for(j=1;j<=nx;j++)
                for(k=1;k<=ny;k++)
                  psip[i][j][k]=a*psi[i][j][k]*(1.0-psi[i][j][k]);
            for(i=0;i<fields;i++)
              for(j=1;j<=nx;j++)
                for(k=1;k<=ny;k++)
                   psi[i][j][k]=psip[i][j][k]+
                    D*(psip[i][j-1][k]+psip[i][j+1][k]+psip[i][j][k-1]+psip[i][j][k+1]
                                -4*psip[i][j][k])/4;;             
            // Make sure boundary conditions still hold
            setBoundaryConditions(psi, nx, ny, fields);                            
            t = t + 1;
            return t;
      }      
      
public void derivs(double[][][] psi, double[][][] dpsi, double t, int nx, int ny, int fields){}        
          
      // Set random initial conditions specified by ic[][]
      // Can override for other i.c. if desired
      public void initialCondition(double[][][] psi, double[][] icp, int nicp) {
        for(j=1;j<=ny;j++) {
            for(i=1;i<=nx;i++) {
                for(k=0;k<fields;k++) {
                   psi[k][i][j]=icp[k][0]*Math.random();
                }   
            }
        }
        setBoundaryConditions(psi, nx, ny, fields);
      }         
    
          
     // Choose what to plot: return field to plot in psir[0]
     public void makePlot(double[][][] psir, int plotwidth, int plotheight) {
               
     }

     
     
     // Choose pallette for plot based on integer plotType set in html file
     // Choices are grey, circ (circular rainbow) and RGB
     public void setPallette() {      
            if(plotType==0) 
                  myPal = new RGBPallette();
            else
                  myPal = new circPallette();
     }
     
}
