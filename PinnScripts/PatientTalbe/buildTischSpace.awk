BEGIN{

  # CT Durchmesser -CTwidth
  CTWidth = 23  ;
 
  getline
  XCoord = 0 ;

  getline  
  YCoord = $0 ;

  getline
  ZCoord = $0 ;

  getline
  BXCoord = $0 ;

  getline
  BYCoord = $0 ;

  p1x = CTWidth +  BXCoord ;
  p1y = YCoord -1 ;
  
  p2x = p1x ;
  p2y = -CTWidth +  BYCoord ;

  p3x = -CTWidth +  BXCoord ;
  p3y = p2y ;

  p4x = p3x ;
  p4y = p1y ;

  p5x = p1x ;
  p5y = p1y ;



  print"//-----------------------------------------------------" ;
  print"//  Beginning of ROI: TischTempSpace" ;
  print"//-----------------------------------------------------" ;
  print"" ;
  print"   roi={" ;
  print"           name: TischTempSpace" ;
  print"           flags =          16;" ;
  print"           color:           grey" ;
  print"           box_size =       5;" ;
  print"           line_2d_width =  1;" ;
  print"           line_3d_width =  1;" ;
  print"           paint_brush_radius =  0.4;" ;
  print"           paint_allow_curve_closing = 1;" ;
  print"           lower =          800;" ;
  print"           upper =          4096;" ;
  print"           radius =         0;" ;
  print"           density =        0.2;" ;
  print"           density_units:   g/cm^3" ;
  print"           override_data =  0;" ;
  print"           invert_density_loading =  0;" ;
  print"           volume =         0;" ;
  print"           pixel_min =      0;" ;
  print"           pixel_max =      0;" ;
  print"           pixel_mean =     0;" ;
  print"           pixel_std =      0;" ;
  print"           num_curve = 1;" ;
  print"           bBEVDRROutline =       0;" ;
  print"//----------------------------------------------------" ;
  print"//  ROI: TischTempSpace" ;
  print"//  Curve 1 of 1" ;
  print"//----------------------------------------------------" ;
  print"               curve={" ;
  print"                       flags =       20;" ;
  print"                       block_size =  32;" ;
  print"                       num_points =  5;" ;
  print"points={" ;
  printf"%6.2f %6.2f %6.2f\n", p1x, p1y, ZCoord ;
  printf"%6.2f %6.2f %6.2f\n", p2x, p2y, ZCoord ;
  printf"%6.2f %6.2f %6.2f\n", p3x, p3y, ZCoord ;
  printf"%6.2f %6.2f %6.2f\n", p4x, p4y, ZCoord ;
  printf"%6.2f %6.2f %6.2f\n", p5x, p5y, ZCoord ;
  print" };  // End of points for curve 1" ;
  print"}; // End of curve 1" ;
  print"        }; // End of ROI TischTempSpace" ;

 }