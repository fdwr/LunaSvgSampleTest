/*
 * @(#)Barkley.java  1.5 3/4/99
 * Copyright (c) 1999, Michael Cross All Rights Reserved.
 * Time stepper for Barkley equation
 */

import java.util.*;

public class Barkley extends fdPDE {
      private double d1;
      private int i,j;
      private double one_m_dt,one_o_a,dt_o_eps,b_o_a;
      private double DELTA,h,D,b; 
      private double amp; 
      private double frequency=0.5;
            
      // Consructor
      public Barkley() {
            fields=2;
            nParameters=5;
            numPlotTypes=2;
            defaultValues=new String[nParameters];
            defaultValues[0]="0.3";
            defaultValues[1]="0.01";
            defaultValues[2]="0.005";
            defaultValues[3]="0.001";
            defaultValues[4]="0.0";
            labels = new String[nParameters];
            labels[0]="  a ";
            labels[1]="  b ";                  
            labels[2]=" eta";
            labels[3]="delta";
            labels[4]=" amp";
      }     

      public double tstep(double[][][] psi, double t) {
     
      double u_th,temp;
      int ktmp;
      
      /* interchange k and kprm */
      ktmp = kprm;
      kprm = k;
      k = ktmp;
      
      /* main loop */
      for(i=1; i<=nx; i++) {
            for(j=1; j<=ny; j++) {
                 /* MCC Include abs */
                 if(Math.abs(psi[0][i][j]) < DELTA ) {
                        psi[0][i][j] = D * lap[k][i][j];
                        psi[1][i][j] = one_m_dt * psi[1][i][j];
                  }
                  /* MCC: Modify for psi[0] near 1 */
                  else if(Math.abs(1-psi[0][i][j]) < DELTA) {
                        psi[0][i][j] = 1. + D * lap[k][i][j];
                        psi[1][i][j] = one_m_dt * psi[1][i][j] + dt;
                  }      
                  else {
                        u_th = one_o_a * psi[1][i][j] + b_o_a;
                        psi[1][i][j] = psi[1][i][j] + dt * (psi[0][i][j] - psi[1][i][j]);
            /*  explicit form for F */
            /*
                        psi[0][i][j] = psi[0][i][j] + dt_o_eps * psi[0][i][j] * 
                         (1.0 - psi[0][i][j]) * (psi[0][i][j] - u_th) + D * lap[k][i][j];
            */                  
            /*  implicit form for F */
            
                  if(psi[0][i][j] < u_th)
                        psi[0][i][j] = psi[0][i][j] / (1. - dt_o_eps *
                        (1.0 - psi[0][i][j]) * (psi[0][i][j] - u_th))+ D * lap[k][i][j];
                  else {
                        temp = dt_o_eps * psi[0][i][j] * (psi[0][i][j] - u_th);
                        psi[0][i][j] = (psi[0][i][j] + temp) / (1. + temp) +
                              D * lap[k][i][j];
                  }
                 
           
                  lap[kprm][i][j]   = lap[kprm][i][j] - 4.*psi[0][i][j];
                  lap[kprm][i+1][j] = lap[kprm][i+1][j] + psi[0][i][j];
                  lap[kprm][i-1][j] = lap[kprm][i-1][j] + psi[0][i][j];
                  lap[kprm][i][j+1] = lap[kprm][i][j+1] + psi[0][i][j];
                  lap[kprm][i][j-1] = lap[kprm][i][j-1] + psi[0][i][j];
                  }
             lap[k][i][j] = 0.;
             }
      }
      //Drving term
      if(amp>0) psi[0][1][1]=amp*(1-Math.sin(frequency*t));
/*    Use to make spiral (b=0.035 works well)
      if(kick) {
            psi[0][3*nx/4][ny/4]=5*amp;
            psi[0][3*nx/4+1][ny/4]=5*amp;
            psi[0][3*nx/4][ny/4+1]=5*amp;
            psi[0][3*nx/4-1][ny/4]=5*amp;
            psi[0][3*nx/4][ny/4-1]=5*amp;
            psi[0][3*nx/4+2][ny/4]=5*amp;
            psi[0][3*nx/4][ny/4+2]=5*amp;
            psi[0][3*nx/4-2][ny/4]=5*amp;
            psi[0][3*nx/4][ny/4-2]=5*amp;         
      }
*/      
        
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
     
     public void initialCondition(double[][][] psi, double[] a, double[] b) {
     
        double x,y,r,theta;
        
        for(int j=1;j<=ny;j++) {
            for(int i=1;i<=nx;i++) {
                x=((double)(i-nx/2))*parameters[3];
                y=((double)(j-ny/2))*parameters[3];
                theta=Math.atan2(x,y);
                r=Math.sqrt(x*x+y*y);
//               psi[1][i][j]=0.5*parameters[0]-parameters[1]+a1*Math.random();                 
//               psi[0][i][j]=a2+a3*Math.random();

               psi[1][i][j]=b[1]*(0.5*parameters[0]-parameters[1])+a[0]*Math.sin(a[1]*r+theta);                 
               psi[0][i][j]=b[1]*0.5+b[0]*Math.cos(a[1]*r+theta);
                if(psi[0][i][j]<0.) psi[0][i][j]=-psi[0][i][j];
                while(psi[0][i][j]>1.) psi[0][i][j]=psi[0][i][j]-1.;
            }
        }      
     }
              
     public void setParameters(int nParameters, double[] in_parameters) {            
            super.setParameters(nParameters, in_parameters);
            one_o_a=1./parameters[0];
            b=parameters[1];            
            b_o_a=b*one_o_a;
            dt_o_eps=dt/parameters[2];
            DELTA=parameters[3];
            amp=parameters[4];           
            D=dt/(mesh*mesh);
            one_m_dt=1.-dt;             
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
