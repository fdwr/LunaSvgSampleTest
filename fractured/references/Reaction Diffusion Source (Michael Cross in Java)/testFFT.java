import java.applet.Applet;
import java.awt.event.*;
import java.awt.*;

public class testFFT extends Applet {
      
    public void init() {
      FFT2D myFFT=new FFT2D();
      int nx=16;
      int ny=16;
      double diff;
      double[][][] psi=new double[2][nx+1][ny+1];
      double[][] psip=new double[nx+1][ny+1];
      for(int j=1;j<=ny;j++) {
         for(int i=1;i<=nx;i++) {
             psi[1][i][j]=(Math.random());
             psip[i][j]=psi[1][i][j];
          }
      }
      myFFT.trfor(psi[1],nx,ny);
      myFFT.trbak(psi[1],nx,ny);
      for(int j=1;j<=ny;j++) {
         for(int i=1;i<=nx;i++) {
             diff=Math.abs(psi[1][i][j]-psip[i][j]);
//             if(diff>1.e-6)
                  System.out.println(i+" "+j+" "+diff);
          }
      }
   }   
}      
      
      
      
      
