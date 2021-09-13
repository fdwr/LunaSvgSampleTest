/*
 * @(#PDE.java  5/1/99
 *
 * Copyright (c) 1999, Michael Cross All Rights Reserved.
 *
 * Stub code for time stepper for PDE 
 */

import java.util.*;

public class PDE {
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
      protected double mesh;
      protected int plotType;
      protected myPallette myPal;                 // Pallette for plotting
                  
      public void init(int width, int height, double[] in_parameters, double in_dt,
                  double in_mesh, int in_plotType) {
                  
            nx = width;
            ny = height;                       
            
            parameters = new double[nParameters];
            for(int i=1;i<nParameters;i++) 
                parameters[i]=in_parameters[i];            
            
            dt=in_dt;
            mesh=in_mesh;
            plotType=in_plotType;
            setPallette();
      }     
      
      // Set initial conditions specified by icp[][]
      public void initialCondition(double[][][] psi, double[][] icp, int nicp) {
      }                               

      // Dummy time stepper. 
      public double tstep(double[][][] psi, double t) {
            return t;
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
