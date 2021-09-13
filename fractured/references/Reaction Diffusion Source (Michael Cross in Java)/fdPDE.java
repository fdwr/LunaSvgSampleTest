/*
 * @(#fdPDE.java  5/7/99
 *
 * Copyright (c) 1999, Michael Cross All Rights Reserved.
 *
 * Stub code for time stepper for finite difference PDE 
 */

import java.util.*;

public class fdPDE extends PDE {
      protected double[][][] lap;
      protected int k,kprm;
      
      // Most of intializataion done in PDE.java
      public void init(int width, int height, double[] in_parameters, double in_dt,
                  double in_mesh, int in_plotType) {
                  
            super.init(width, height, in_parameters, in_dt, in_mesh, in_plotType);
            
            nInitialParameters=2;
                        
            spectral=false;
            lap = new double[2][nx+2][ny+2];
            for(int m=0;m<2;m++)
               for(int i=0;i<nx+2;i++)
                   for(int j=0;j<ny+2;j++)
                        lap[m][i][j]=0.;
            
            k=0;
            kprm=1;            
      }     

      public double tstep(double[][][] psi, double t) {
            return t;
      }
     
      // Set random initial conditions specified by ic[][]
      // Can override for other i.c. if desired
      public void initialCondition(double[][][] psi, double[][] icp, int nicp) {
        for(int j=1;j<=ny;j++) {
            for(int i=1;i<=nx;i++) {
                for(int k=0;k<fields;k++) {
                   psi[k][i][j]=icp[k][0]*(Math.random()-0.5)+icp[k][1];
                }   
            }
        }
      }                                    
}
