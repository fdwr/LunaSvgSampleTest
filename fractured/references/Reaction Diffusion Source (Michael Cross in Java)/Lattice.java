/*
 * @(#Lattice.java  2/16/024
 *
 * Copyright (c) 2004, Michael Cross All Rights Reserved.
 *
 * Stub code for time stepper for Lattice of ODEs or maps 
 */

import java.util.*;

public class Lattice {
      protected double[] parameters;
      
      public int nParameters;
      public int nInitialParameters=2;
      public int fields;
      public String[] defaultValues;
      public String[] labels;
      public boolean spectral;
      public int numPlotTypes=1;
      
      protected int scalex;
      protected int scaley;
      protected int nx,ny;
      protected double dt;
      protected int plotType;
      protected myPallette myPal;                 // Pallette for plotting
      protected int i,j,k;
      
      protected double[][][] psip;
      
                
      public void init(int width, int height, double[] in_parameters, double in_dt,
                  int in_plotType) {
                  
            nx = width;
            ny = height;
            psip = new double[fields][width+2][height+2];
                                             
            
            parameters = new double[nParameters];
            for(i=1;i<nParameters;i++) 
                parameters[i]=in_parameters[i];            
            
            dt=in_dt;
            plotType=in_plotType;
            setPallette();
      }         
      
          
      // Set random initial conditions specified by ic[][]
      // Can override for other i.c. if desired
      public void initialCondition(double[][][] psi, double[][] icp, int nicp) {
        for(j=1;j<=ny;j++) {
            for(i=1;i<=nx;i++) {
                for(k=0;k<fields;k++) {
                   psi[k][i][j]=icp[k][0]*(Math.random()-0.5)+icp[k][1];
                }   
            }
        }
        setBoundaryConditions(psi, nx, ny, fields);
      }                                            

      // Dummy time stepper. 
      public double tstep(double[][][] psi, double t) {
            return t;
      } 
       
      
     public double[][][] setBoundaryConditions(double[][][] psi, int nx, int ny, int fields) {
        int i,j,k;
 
        for(i=0;i<fields;i++) {
            for(j=1;j<=nx;j++) {
                psi[i][j][0]=psi[i][j][ny];
                psi[i][j][ny+1]=psi[i][j][1];
            }
            for(k=1;k<=ny;k++) {
                psi[i][0][k]=psi[i][nx][k];
                psi[i][nx+1][k]=psi[i][1][k];
            }
        psi[i][0][0]=0;
        psi[i][nx+1][0]=0;
        psi[i][0][ny+1]=0;
        psi[i][nx+1][ny+1]=0;
        } 
                       
        return psi;
     }                     
      
     // Forms plot from two fields depending on plotType: to be over-ridden
     public void makePlot(double[][][] psir, int plotwidth, int plotheight) {
     }

     // Forms plot from two fields depending on plotType: to be over-ridden
     public void makeFFTPlot(double[][][] psir, int plotwidth, int plotheight) {
     }
     
     public void setParameters(int nParameters, double[] in_parameters) {            
            for(int i=0;i<nParameters;i++) 
                parameters[i]=in_parameters[i];                
     }
     
     public myPallette getPallette() {
           return myPal;
     }
     
     public void setPlotType(int in_plotType) {
           plotType=in_plotType;
     }
     
     public void setPallette() {      
           myPal = new myPallette();
     }                       

     public void setPallette(int palletteType) {      
        switch (palletteType) {
             case 0:
                   setPallette();
                   break;
             case 1:
                   myPal = new RGBPallette();
                   break;                   
             case 2:
                   myPal = new greyPallette();
                   break;                        
             case 3:
                   myPal = new circPallette();
                   break;
             case 4:
                   myPal = new myPallette();
                   break;
             default:
                   setPallette();
                   break;
        }
    }
    
    public void setScales(int sx, int sy) {
        scalex=sx;
        scaley=sy;
    }                         
}
