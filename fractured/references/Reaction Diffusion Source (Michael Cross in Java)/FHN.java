/*
 * @(#)Barkley.java  1.5 3/4/99
 * Copyright (c) 1999, Michael Cross All Rights Reserved.
 * Time stepper for FHN equation
 */

import java.util.*;

public class FHN extends fdPDE {
      int i,j;
      double eps;
      double a,D,g,w;      
            
      // Consructor
      public FHN() {
            fields=2;
            nParameters=5;
            numPlotTypes=2;
            spectral=false;
            defaultValues=new String[nParameters];
            defaultValues[0]="0.5";
            defaultValues[1]="0.0";
            defaultValues[2]="1.95";
            defaultValues[3]="0.0";
            defaultValues[4]="0.0";
            labels = new String[nParameters];
            labels[0]="  a ";                  
            labels[1]="  D  ";
            labels[2]=" eps ";
            labels[3]="Gamma";
            labels[4]="omega";
      }     

      public double tstep(double[][][] psi, double t) {
     
      int i,j;
      double u_th,temp;
      int ktmp;
      
      /* interchange k and kprm */
      ktmp = kprm;
      kprm = k;
      k = ktmp;
      
      /* main loop */
      for(i=1; i<=nx; i++) {
            for(j=1; j<=ny; j++) {
                  u_th=psi[1][i][j];
                  psi[1][i][j] = psi[1][i][j] + dt * eps * (psi[0][i][j] - a*psi[1][i][j]);                  
                  psi[0][i][j] = psi[0][i][j]
                        +dt*((1.-(1+g*Math.cos(w*t))*psi[0][i][j]*psi[0][i][j])*psi[0][i][j]-u_th)
                         + D * dt * lap[k][i][j]; 

                  lap[kprm][i][j]   = lap[kprm][i][j] - 4.*psi[0][i][j];
                  lap[kprm][i+1][j] = lap[kprm][i+1][j] + psi[0][i][j];
                  lap[kprm][i-1][j] = lap[kprm][i-1][j] + psi[0][i][j];
                  lap[kprm][i][j+1] = lap[kprm][i][j+1] + psi[0][i][j];
                  lap[kprm][i][j-1] = lap[kprm][i][j-1] + psi[0][i][j];
 
                  lap[k][i][j] = 0.;
             }
      }
        
      /* impose no-flux boundary conditions */
      for(i=1; i<=nx; i++) {
            lap[kprm][i][1] = lap[kprm][i][1] + psi[0][i][2];
            lap[kprm][i][ny] = lap[kprm][i][ny] + psi[0][i][ny-1];
      }
      for(j=1; j<=ny; j++) {      
            lap[kprm][1][j] = lap[kprm][1][j] + psi[0][2][j];
            lap[kprm][nx][j] = lap[kprm][nx][j] + psi[0][nx-1][j];
      }
      t = t + dt;
//      System.out.println("k= "+k+" kp= "+kprm+" dt= "+dt+" D= "+D+" dt_o_eps= "+dt_o_eps+" b_o_a= "+
//                b_o_a+" one_o_a= "+one_o_a);

      return t;
      }

     
             
     public void setParameters(int nParameters, double[] in_parameters) {            
            super.setParameters(nParameters, in_parameters);
            a=parameters[0];            
            D=parameters[1];
            eps=parameters[2];
            g=parameters[3];
            w=parameters[4];
     }
          
     // Forms plot from two fields depending on plotType
     public void makePlot(double[][][] psir, int plotwidth, int plotheight) {

        if(plotType==1) {  
          for(j=1;j<=plotheight;j++) {
             for(i=1;i<=plotwidth;i++) {
                   psir[0][i][j] = psir[1][i][j];
             }
          }
        }                    
     }
          
     public void setPallette() {      
                  myPal = new RGBPallette();
     }             
}
