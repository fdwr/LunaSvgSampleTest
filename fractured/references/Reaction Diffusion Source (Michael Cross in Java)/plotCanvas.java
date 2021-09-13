import java.applet.Applet;
import java.awt.event.*;
import java.awt.*;
import java.awt.image.ColorModel;
import java.awt.image.MemoryImageSource;
import java.lang.InterruptedException;


public class plotCanvas extends Canvas {
    Image img;
    boolean scalePlot=true;
    int plotwidth, plotheight,w,h; 

    public void paint(Graphics g) {
      if(scalePlot) {
          w = getSize().width;
          h = getSize().height;
          w=h= (w < h) ? w : h;
          w=w-20;
      }
      else {
          w=plotwidth;
          h=plotheight;
      }        
 
      if (img == null) {
//          super.paint(g);
      } else {             
            g.drawImage(img, 10, 10, w, h, this);
      }
    }

    public void update(Graphics g) {
      paint(g);
    }
    
    public void setSize(int width, int height) {
          plotwidth=width;
          plotheight=height;
          scalePlot=false;
    }

    // Next few methods are for interacting with GUI
    public Dimension getMinimumSize() {
      return new Dimension(20, 20);
    }

    public Dimension getPreferredSize() {
      return new Dimension(276, 276);
    }

    public Image getImage() {
      return img;
    }

    public void setImage(Image img) {
      this.img = img;
        paint(getGraphics());
    }
}

