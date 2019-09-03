PRO cunchugeshi
  COMPILE_OPT IDL2
  ; Start the application
  e = ENVI(/HEADLESS)
  ;  ; A Landsat 8 OLI dataset consists of one TIFF file per band,
  ;  ; with an associated metadata file (*_MTL.txt). Open the
  ;  ; metadata file to automatically read the gains and offsets.
  ;  File = File_Search('C:\LC08_L1TP_062047_20170628_20170628_01_RT','*_MTL.txt')
  ;第一大步:辐射亮度定标
  ;打开LC8 MTL.txt文件
  MTLFile_address=ENVI_PICKFILE(TITLE='请选择 Landsat8头文件', FILTER='*_MTL.txt')
  ;Raster = e.OpenRaster(File)
  RawRaster=e.OpenRaster(MTLFile_address);通过地址打开这个数据集,一共五部分数据集
  Mul_RawRaster=RawRaster[0];获得第一部分数据集,也就是MultiSpectral部分,共7个波段
  MulRaw_fid=ENVIRasterToFID(Mul_RawRaster)
  Tir_RawRaster=RawRaster[3];反射率文件没有热红外
  TirRaw_fid=ENVIRasterToFID(Tir_RawRaster)
  ;设置输出文件名
  MTLfile_name=FILE_BASENAME(MTLFile_address);通过地址得到数据文件名
  pPos=STRPOS(MTLfile_name,'.',/reverse_search);pPos为'.'的位置
  imageprefix=strmid(MTLfile_name,0,pPos-18) ;imageprefix为原先去除后缀后的文件名,
  ;去掉了MLT.dat后缀了
  ;获取现在的儒略历时间，换算为公历，将时间存入内存
  caldat,systime(/JULIAN),month,day,year,hour,min,sec
  ;将年份去掉前后空格
  year=strtrim(year,2)
  ;如果月份在1月到9月之间
  if((month ge 1)and(month le 9))then begin
    month=strjoin(['0',strtrim(month,2)]);把月份前后的空格去掉，在前面加0
  endif else begin
    month=strtrim(month,2);否则无需加0，只把月份前后的空格去掉即可
  endelse
  ;如果日期在1日到9日之间
  if((day ge 1)and(day le 9))then begin
    day=strjoin(['0',strtrim(day,2)]);把日期前后的空格去掉，在前面加0
  endif else begin
    day=strtrim(day,2);否则无需加0，只把日期前后的空格去掉即可
  endelse
  ;如果小时在0时到9时之间
  if((hour ge 0)and(hour le 9))then begin
    hour=strjoin(['0',strtrim(hour,2)]);把小时前后的空格去掉，在前面加0
  endif else begin
    hour=strtrim(hour,2);否则无需加0，只把小时前后的空格去掉即可
  endelse
  ;如果分钟在0分到9分之间
  if((min ge 0)and(min le 9))then begin
    min=strjoin(['0',strtrim(min,2)]);把分钟前后的空格去掉，在前面加0
  endif else begin
    min=strtrim(min,2);否则无需加0，只把分钟前后的空格去掉即可
  endelse
  ;如果秒钟在0秒到10秒之间（注意：秒钟是双精度浮点的小数）
  if((sec ge 0)and(sec lt 10))then begin
    ;把秒钟转换为无符号整型，前后的空格去掉，在前面加0
    sec=strjoin(['0',strtrim(UINT(sec),2)])
  endif else begin
    ;否则无需加0，只把秒钟转换为无符号整型，把秒钟前后的空格去掉即可
    sec=strtrim(UINT(sec),2)
  endelse
  ;输出当前的时间
  foldername=imageprefix+year+month+day+hour+min+sec
  ;print,foldername
  file_mkdir,'C:\'+foldername+'
  ; Get the radiometric calibration task from the catalog of ENVI tasks.
  Task = ENVITask('RadiometricCalibration')
  ; Define inputs. Since radiance is the default calibration method
  ; you do not need to specify it here.
  Task.Input_Raster = RawRaster[0] ; Bands 1-7
  Task.Output_Data_Type = 'Float'
  Task.Scale_Factor = 0.1
  ; Define output raster URI
  ;Task.Output_Raster_URI = e.GetTemporaryFilename()
  Task.Output_Raster_URI = 'C:\'+foldername+'\'+imageprefix+'Radiance_BSQ.dat'
  ; Run the task
  Task.Execute
  ; Get the data collection
  DataColl = e.Data
  ; Add the output to the data collection
  DataColl.Add, Task.Output_Raster
  ; Close the ENVI session
  ;e.Close
  Mul_radiance_raster=e.OpenRaster(Task.Output_Raster_URI);通过地址打开这个数据集
  ;,一共五部分数据集
  MulRadRaster=Mul_radiance_raster[0];获得第一部分数据集,
  ;也就是MultiSpectral部分,共7个波段
  MulRad_fid=ENVIRasterToFID(MulRadRaster)
  ;获得数据各种信息,其中增益值和偏移值由data_gains,data_offsets获得
  ENVI_FILE_QUERY,MulRad_fid,data_gains=data_gains,$
    ns=Mul_ns,nl=Mul_nl,nb=Mul_nb,dims=dims,$
    data_offsets=data_offsets,bnames=bnames,r_fid=Mul_fid
  ;转换存储格式为BIL,指定文件夹输出,输出时在原名的基础上加了后缀'_radiance'
  Envi_doit,'convert_doit',fid=MulRad_fid,pos=lindgen(mul_nb),$
    dims=dims,$
    out_name='C:\'+foldername+'\'+imageprefix+'Radiance.dat',$
    o_interleave=1,r_fid=BIL_fid
