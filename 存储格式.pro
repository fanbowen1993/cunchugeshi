PRO cunchugeshi
  COMPILE_OPT IDL2
  ; Start the application
  e = ENVI(/HEADLESS)
  ;  ; A Landsat 8 OLI dataset consists of one TIFF file per band,
  ;  ; with an associated metadata file (*_MTL.txt). Open the
  ;  ; metadata file to automatically read the gains and offsets.
  ;  File = File_Search('C:\LC08_L1TP_062047_20170628_20170628_01_RT','*_MTL.txt')
  ;��һ��:�������ȶ���
  ;��LC8 MTL.txt�ļ�
  MTLFile_address=ENVI_PICKFILE(TITLE='��ѡ�� Landsat8ͷ�ļ�', FILTER='*_MTL.txt')
  ;Raster = e.OpenRaster(File)
  RawRaster=e.OpenRaster(MTLFile_address);ͨ����ַ��������ݼ�,һ���岿�����ݼ�
  Mul_RawRaster=RawRaster[0];��õ�һ�������ݼ�,Ҳ����MultiSpectral����,��7������
  MulRaw_fid=ENVIRasterToFID(Mul_RawRaster)
  Tir_RawRaster=RawRaster[3];�������ļ�û���Ⱥ���
  TirRaw_fid=ENVIRasterToFID(Tir_RawRaster)
  ;��������ļ���
  MTLfile_name=FILE_BASENAME(MTLFile_address);ͨ����ַ�õ������ļ���
  pPos=STRPOS(MTLfile_name,'.',/reverse_search);pPosΪ'.'��λ��
  imageprefix=strmid(MTLfile_name,0,pPos-18) ;imageprefixΪԭ��ȥ����׺����ļ���,
  ;ȥ����MLT.dat��׺��
  ;��ȡ���ڵ�������ʱ�䣬����Ϊ��������ʱ������ڴ�
  caldat,systime(/JULIAN),month,day,year,hour,min,sec
  ;�����ȥ��ǰ��ո�
  year=strtrim(year,2)
  ;����·���1�µ�9��֮��
  if((month ge 1)and(month le 9))then begin
    month=strjoin(['0',strtrim(month,2)]);���·�ǰ��Ŀո�ȥ������ǰ���0
  endif else begin
    month=strtrim(month,2);���������0��ֻ���·�ǰ��Ŀո�ȥ������
  endelse
  ;���������1�յ�9��֮��
  if((day ge 1)and(day le 9))then begin
    day=strjoin(['0',strtrim(day,2)]);������ǰ��Ŀո�ȥ������ǰ���0
  endif else begin
    day=strtrim(day,2);���������0��ֻ������ǰ��Ŀո�ȥ������
  endelse
  ;���Сʱ��0ʱ��9ʱ֮��
  if((hour ge 0)and(hour le 9))then begin
    hour=strjoin(['0',strtrim(hour,2)]);��Сʱǰ��Ŀո�ȥ������ǰ���0
  endif else begin
    hour=strtrim(hour,2);���������0��ֻ��Сʱǰ��Ŀո�ȥ������
  endelse
  ;���������0�ֵ�9��֮��
  if((min ge 0)and(min le 9))then begin
    min=strjoin(['0',strtrim(min,2)]);�ѷ���ǰ��Ŀո�ȥ������ǰ���0
  endif else begin
    min=strtrim(min,2);���������0��ֻ�ѷ���ǰ��Ŀո�ȥ������
  endelse
  ;���������0�뵽10��֮�䣨ע�⣺������˫���ȸ����С����
  if((sec ge 0)and(sec lt 10))then begin
    ;������ת��Ϊ�޷������ͣ�ǰ��Ŀո�ȥ������ǰ���0
    sec=strjoin(['0',strtrim(UINT(sec),2)])
  endif else begin
    ;���������0��ֻ������ת��Ϊ�޷������ͣ�������ǰ��Ŀո�ȥ������
    sec=strtrim(UINT(sec),2)
  endelse
  ;�����ǰ��ʱ��
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
  Mul_radiance_raster=e.OpenRaster(Task.Output_Raster_URI);ͨ����ַ��������ݼ�
  ;,һ���岿�����ݼ�
  MulRadRaster=Mul_radiance_raster[0];��õ�һ�������ݼ�,
  ;Ҳ����MultiSpectral����,��7������
  MulRad_fid=ENVIRasterToFID(MulRadRaster)
  ;������ݸ�����Ϣ,��������ֵ��ƫ��ֵ��data_gains,data_offsets���
  ENVI_FILE_QUERY,MulRad_fid,data_gains=data_gains,$
    ns=Mul_ns,nl=Mul_nl,nb=Mul_nb,dims=dims,$
    data_offsets=data_offsets,bnames=bnames,r_fid=Mul_fid
  ;ת���洢��ʽΪBIL,ָ���ļ������,���ʱ��ԭ���Ļ����ϼ��˺�׺'_radiance'
  Envi_doit,'convert_doit',fid=MulRad_fid,pos=lindgen(mul_nb),$
    dims=dims,$
    out_name='C:\'+foldername+'\'+imageprefix+'Radiance.dat',$
    o_interleave=1,r_fid=BIL_fid
