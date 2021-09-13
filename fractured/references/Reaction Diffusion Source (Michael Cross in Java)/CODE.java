/*
 * @(#CODE.java  2/16/04
 *
 * Copyright (c) 2004, Michael Cross All Rights Reserved.
 *
 * Time stepper for coupled ODEs 
 */

import java.util.*;

public class CODE extends Lattice {
      
      protected double[][][] k1;
      protected double[][][] k2;
      protected double[][][] k3;
      protected double[][][] k4;
      protected double[][][] k5;
      protected double[][][] k6;      
      protected double[][][] dpsi;
                  
      public void init(int width, int height, double[] in_parameters, double in_dt,
                  int in_plotType) {
                  
            super.init(width, height, in_parameters, in_dt, in_plotType);
            
            dpsi = new double[fields][width+2][height+2];
            k1 = new double[fields][width+2][height+2];
            k2 = new double[fields][width+2][height+2];  
            k3 = new double[fields][width+2][height+2];                       
            k4 = new double[fields][width+2][height+2];                       
            k5 = new double[fields][width+2][height+2];                                            
            k6 = new double[fields][width+2][height+2];                                   
            
      }   

      // RK4 time stepper. 
      public double tstep(double[][][] psi, double t) {
                   
            derivs(psi,k1,t,nx,ny,fields);
            for(i=0;i<fields;i++)
              for(j=1;j<=nx;j++)
                for(k=1;k<=ny;k++)
                  psip[i][j][k]=psi[i][j][k]+0.5*dt*k1[i][j][k];
            setBoundaryConditions(psip, nx, ny, fields);
            derivs(psip,k2,t+0.5*dt,nx,ny,fields);
            for(i=0;i<fields;i++)
              for(j=1;j<=nx;j++)
                for(k=1;k<=ny;k++)
                  psip[i][j][k]=psi[i][j][k]+0.5*dt*k2[i][j][k];
            setBoundaryConditions(psip, nx, ny, fields);
            derivs(psip,k3,t+0.5*dt,nx,ny,fields);
            for(i=0;i<fields;i++)
              for(j=1;j<=nx;j++)
                for(k=1;k<=ny;k++)
                  psip[i][j][k]=psi[i][j][k]+dt*k3[i][j][k];
            setBoundaryConditions(psip, nx, ny, fields);
            derivs(psip,k4,t+dt,nx,ny,fields);
            for(i=0;i<fields;i++)
              for(j=1;j<=nx;j++)
                for(k=1;k<=ny;k++)
                  psi[i][j][k]=psi[i][j][k]+dt*(0.5*k1[i][j][k]+k2[i][j][k]+k3[i][j][k]+0.5*k4[i][j][k])/3.;
            
            // Make sure boundary conditions still hold
            setBoundaryConditions(psi, nx, ny, fields); 
                           
            t = t + dt;
            return t;
      }      
      
        public void derivs(double[][][] psi, double[][][] dpsi, double t, int nx, int ny, int fields){}        
              
}
