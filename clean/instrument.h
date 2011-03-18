//Set of C++ wave table function 
//©Romain Michon (rmichon@ccrma.stanford.edu), 2011
//licence: STK-4.3

#include <stdio.h>
#include <stdlib.h>

#ifndef _LOOKUP_TABLE_H_
#define _LOOKUP_TABLE_H_

#define TABLE_SIZE 1024

class LookupTable
{
public:
	LookupTable(double *points, int num_points);
	double getValue(double x);
	
protected:
	
	// Note: Actual array size is 2*m_nPoints;
	double *m_Points;
	int m_nPoints;
};

#endif // _LOOKUP_TABLE_H_

LookupTable::LookupTable(double *points, int num_points)
{
	// Note: Actual array size is 2*num_points
	
	m_Points = points;
	m_nPoints = num_points;
}

double LookupTable::getValue(double x)
{
	// Note: Assumes points are monotonically increasing in X!
	
	int i=0;
	while (x>m_Points[i*2] && i<m_nPoints)
		i++;
	
	if (i==0)
		return m_Points[1];
	
	if (i>=m_nPoints)
		return m_Points[(m_nPoints-1)*2+1];
	
	double ratio =
	(x - m_Points[(i-1)*2])
	/ (m_Points[i*2] - m_Points[(i-1)*2]);
	
	return m_Points[(i-1)*2+1]*(1-ratio) + m_Points[i*2+1]*(ratio);
}

//impulse response of a vocal tract for formant synthesis
float readImpuls20(int index){
	static float impuls20[TABLE_SIZE/4] = {
		0.999908447265625, 0.957305908203125, 0.835571289062500, 0.652893066406250, 0.435516357421875, 
		0.213806152343750, 0.016601562500000, -0.133178710937500, -0.222106933593750, -0.247985839843750, 
		-0.218902587890625, -0.151367187500000, -0.066436767578125, 0.015106201171875, 0.075836181640625, 
		0.105194091796875, 0.100646972656250, 0.067382812500000, 0.016021728515625, -0.039520263671875, 
		-0.086242675781250, -0.114166259765625, -0.118438720703125, -0.100219726562500, -0.065612792968750, 
		-0.023986816406250, 0.014312744140625, 0.040405273437500, 0.049133300781250, 0.039459228515625, 
		0.014984130859375, -0.017608642578125, -0.049987792968750, -0.074493408203125, -0.085784912109375, 
		-0.081726074218750, -0.064239501953125, -0.038146972656250, -0.010192871093750, 0.012908935546875, 
		0.025756835937500, 0.025665283203125, 0.013397216796875, -0.007690429687500, -0.032135009765625, 
		-0.053802490234375, -0.067657470703125, -0.070678710937500, -0.062408447265625, -0.045318603515625, 
		-0.023956298828125, -0.003509521484375, 0.010986328125000, 0.016235351562500, 0.011291503906250, 
		-0.002319335937500, -0.021087646484375, -0.040283203125000, -0.055206298828125, -0.062194824218750, 
		-0.060058593750000, -0.049316406250000, -0.032928466796875, -0.014984130859375, -0.000030517578125, 
		0.008544921875000, 0.008666992187500, 0.000610351562500, -0.013671875000000, -0.030242919921875, 
		-0.045288085937500, -0.055023193359375, -0.057128906250000, -0.051422119140625, -0.039245605468750, 
		-0.023803710937500, -0.009033203125000, 0.001678466796875, 0.005554199218750, 0.001892089843750, 
		-0.008300781250000, -0.022430419921875, -0.036956787109375, -0.048339843750000, -0.053802490234375, 
		-0.052093505859375, -0.043762207031250, -0.030853271484375, -0.016754150390625, -0.004852294921875, 
		0.001953125000000, 0.002044677734375, -0.004486083984375, -0.016052246093750, -0.029632568359375, 
		-0.042022705078125, -0.049957275390625, -0.051788330078125, -0.046905517578125, -0.036682128906250, 
		-0.023681640625000, -0.011108398437500, -0.002075195312500, 0.001220703125000, -0.001922607421875, 
		-0.010803222656250, -0.023132324218750, -0.035705566406250, -0.045684814453125, -0.050415039062500, 
		-0.048889160156250, -0.041442871093750, -0.029937744140625, -0.017333984375000, -0.006622314453125, 
		-0.000518798828125, -0.000457763671875, -0.006469726562500, -0.017120361328125, -0.029602050781250, 
		-0.040924072265625, -0.048309326171875, -0.049835205078125, -0.045318603515625, -0.035644531250000, 
		-0.023437500000000, -0.011627197265625, -0.003082275390625, 0.000000000000000, -0.003051757812500, 
		-0.011596679687500, -0.023468017578125, -0.035644531250000, -0.045318603515625, -0.049865722656250, 
		-0.048278808593750, -0.040954589843750, -0.029571533203125, -0.017059326171875, -0.006530761718750, 
		-0.000427246093750, -0.000518798828125, -0.006652832031250, -0.017242431640625, -0.029998779296875, 
		-0.041473388671875, -0.048858642578125, -0.050476074218750, -0.045684814453125, -0.035736083984375, 
		-0.023040771484375, -0.010864257812500, -0.001953125000000, 0.001220703125000, -0.002044677734375, 
		-0.011138916015625, -0.023651123046875, -0.036682128906250, -0.046905517578125, -0.051788330078125, 
		-0.049987792968750, -0.041992187500000, -0.029663085937500, -0.016052246093750, -0.004425048828125, 
		0.002014160156250, 0.001922607421875, -0.004760742187500, -0.016784667968750, -0.030914306640625, 
		-0.043701171875000, -0.052154541015625, -0.053802490234375, -0.048339843750000, -0.036956787109375, 
		-0.022430419921875, -0.008270263671875, 0.001922607421875, 0.005523681640625, 0.001647949218750, 
		-0.008972167968750, -0.023803710937500, -0.039245605468750, -0.051422119140625, -0.057189941406250, 
		-0.054992675781250, -0.045288085937500, -0.030303955078125, -0.013580322265625, 0.000518798828125, 
		0.008666992187500, 0.008544921875000, 0.000000000000000, -0.015014648437500, -0.032958984375000, 
		-0.049285888671875, -0.060058593750000, -0.062255859375000, -0.055114746093750, -0.040283203125000, 
		-0.021118164062500, -0.002319335937500, 0.011291503906250, 0.016235351562500, 0.010955810546875, 
		-0.003509521484375, -0.023925781250000, -0.045379638671875, -0.062377929687500, -0.070648193359375, 
		-0.067657470703125, -0.053863525390625, -0.032073974609375, -0.007690429687500, 0.013397216796875, 
		0.025695800781250, 0.025726318359375, 0.012908935546875, -0.010192871093750, -0.038085937500000, 
		-0.064270019531250, -0.081756591796875, -0.085784912109375, -0.074493408203125, -0.049987792968750, 
		-0.017578125000000, 0.014984130859375, 0.039428710937500, 0.049133300781250, 0.040405273437500, 
		0.014282226562500, -0.023986816406250, -0.065612792968750, -0.100189208984375, -0.118438720703125, 
		-0.114196777343750, -0.086242675781250, -0.039550781250000, 0.016052246093750, 0.067382812500000, 
		0.100646972656250, 0.105194091796875, 0.075836181640625, 0.015075683593750, -0.066375732421875, 
		-0.151336669921875, -0.218963623046875, -0.247924804687500, -0.222137451171875, -0.133209228515625, 
		0.016571044921875, 0.213836669921875, 0.435546875000000, 0.652862548828125, 0.835601806640625, 
		0.957275390625000};
	return impuls20[index];
};

//stick for modal synthesis
float readMarmstk1(int index){
	static float marmstk1[TABLE_SIZE/4] = {
		0.000579833984375, -0.003417968750000, 0.015930175781250, -0.037689208984375, 0.062866210937500, 
		0.168640136718750, -0.226287841796875, -0.020233154296875, 0.017120361328125, 0.032745361328125, 
		0.028198242187500, -0.065704345703125, 0.102355957031250, -0.135375976562500, -0.088378906250000, 
		0.135375976562500, 0.036987304687500, 0.030181884765625, -0.023498535156250, -0.050872802734375, 
		0.120574951171875, -0.223419189453125, 0.235260009765625, -0.296081542968750, 0.384582519531250, 
		-0.363708496093750, 0.206207275390625, 0.076873779296875, -0.262420654296875, 0.306579589843750, 
		-0.349090576171875, 0.359161376953125, -0.304809570312500, 0.156860351562500, 0.022552490234375, 
		-0.063598632812500, 0.017425537109375, 0.024505615234375, -0.016296386718750, -0.056304931640625, 
		0.093536376953125, -0.108825683593750, 0.215484619140625, -0.354858398437500, 0.316925048828125, 
		-0.164672851562500, 0.028594970703125, 0.095001220703125, -0.165679931640625, 0.218811035156250, 
		-0.239105224609375, 0.182830810546875, -0.026275634765625, -0.016601562500000, -0.042175292968750, 
		0.080566406250000, -0.123352050781250, 0.071563720703125, -0.021514892578125, -0.000488281250000, 
		0.080139160156250, -0.188354492187500, 0.230712890625000, -0.172271728515625, 0.033325195312500, 
		0.111236572265625, -0.127532958984375, 0.118682861328125, -0.136383056640625, 0.068878173828125, 
		0.041931152343750, -0.126129150390625, 0.134155273437500, -0.024902343750000, -0.094726562500000, 
		0.136840820312500, -0.140930175781250, 0.123962402343750, -0.080383300781250, -0.033691406250000, 
		0.167541503906250, -0.194976806640625, 0.151489257812500, -0.042388916015625, -0.028625488281250, 
		0.030853271484375, -0.079559326171875, 0.071166992187500, 0.026977539062500, -0.075714111328125, 
		0.110107421875000, -0.076507568359375, -0.043426513671875, 0.063110351562500, -0.099487304687500, 
		0.137664794921875, -0.086181640625000, 0.047119140625000, 0.022491455078125, -0.092956542968750, 
		0.070709228515625, -0.036560058593750, -0.004943847656250, 0.051208496093750, -0.042541503906250, 
		0.042114257812500, -0.024414062500000, -0.039916992187500, 0.082580566406250, -0.094451904296875, 
		0.039459228515625, 0.037048339843750, -0.061218261718750, 0.080810546875000, -0.070159912109375, 
		0.037139892578125, 0.008789062500000, -0.078094482421875, 0.094024658203125, -0.048431396484375, 
		0.009643554687500, 0.020263671875000, -0.032379150390625, 0.021820068359375, -0.021270751953125, 
		-0.033203125000000, 0.102172851562500, -0.089721679687500, 0.052856445312500, -0.001495361328125, 
		-0.070404052734375, 0.109436035156250, -0.104156494140625, 0.116302490234375, -0.074310302734375, 
		-0.004425048828125, 0.061309814453125, -0.090698242187500, 0.056732177734375, -0.015380859375000, 
		-0.010406494140625, 0.019622802734375, 0.000213623046875, -0.017272949218750, 0.065399169921875, 
		-0.119842529296875, 0.105499267578125, -0.051391601562500, -0.024383544921875, 0.085968017578125, 
		-0.099731445312500, 0.121948242187500, -0.098876953125000, 0.038085937500000, 0.034362792968750, 
		-0.071441650390625, 0.039550781250000, -0.017272949218750, -0.001708984375000, 0.031402587890625, 
		-0.027740478515625, 0.013183593750000, 0.013488769531250, -0.083831787109375, 0.103637695312500, 
		-0.061645507812500, 0.026947021484375, 0.036499023437500, -0.078735351562500, 0.089294433593750, 
		-0.090393066406250, 0.034820556640625, 0.019500732421875, -0.070129394531250, 0.102569580078125, 
		-0.070922851562500, 0.039672851562500, 0.020507812500000, -0.078674316406250, 0.065002441406250, 
		-0.045806884765625, 0.027801513671875, 0.012115478515625, -0.018829345703125, 0.015594482421875, 
		-0.010772705078125, -0.042938232421875, 0.062103271484375, -0.032745361328125, 0.004791259765625, 
		0.028137207031250, -0.067687988281250, 0.078094482421875, -0.063049316406250, 0.039215087890625, 
		0.012359619140625, -0.052337646484375, 0.074401855468750, -0.063629150390625, 0.034362792968750, 
		0.013732910156250, -0.044189453125000, 0.042419433593750, -0.047210693359375, 0.019897460937500, 
		0.020538330078125, -0.039825439453125, 0.048675537109375, -0.025726318359375, -0.016998291015625, 
		0.038482666015625, -0.056060791015625, 0.061584472656250, -0.014343261718750, -0.023101806640625, 
		0.051849365234375, -0.069854736328125, 0.043853759765625, -0.016662597656250, 0.002380371093750, 
		0.033721923828125, -0.039733886718750, 0.021148681640625, -0.010375976562500, 0.000000000000000, 
		0.000000000000000, 0.000000000000000, -0.000030517578125, 0.000030517578125, 0.000000000000000, 
		0.000000000000000, -0.000030517578125, -0.000030517578125, 0.000030517578125, 0.000030517578125, 
		-0.000061035156250, 0.000000000000000, 0.000000000000000, 0.000000000000000, 0.000030517578125, 
		-0.000030517578125, 0.000000000000000, 0.000030517578125, -0.000030517578125, 0.000000000000000, 
		0.000061035156250, -0.000061035156250, 0.000030517578125, 0.000000000000000, -0.000030517578125, 
		0.000000000000000, 0.000061035156250, 0.000000000000000, -0.000030517578125, 0.000000000000000, 
		0.000030517578125};
	return marmstk1[index];
};

//********************************************************************
//bass filter values
//********************************************************************

double bassLoopFilterb0_points[19*2] = {
	24.000,0.54355,
	26.000,0.54355,
	27.000,0.55677,
	29.000,0.55677,
	32.000,0.55677,
	33.000,0.83598,
	36.000,0.83598,
	43.000,0.83598,
	44.000,0.88292,
	48.000,0.88292,
	51.000,0.88292,
	52.000,0.77805,
	54.000,0.77805,
	57.000,0.77805,
	58.000,0.91820,
	60.000,0.91820,
	61.000,0.91820,
	63.000,0.94594,
	65.000,0.91820,
};
extern LookupTable bassLoopFilterb0;
LookupTable bassLoopFilterb0(&bassLoopFilterb0_points[0], 18);

float getValueBassLoopFilterb0(float index){
	return bassLoopFilterb0.getValue(index);
}

double bassLoopFilterb1_points[19*2] = {
	24.000,-0.36586,
	26.000,-0.36586,
	27.000,-0.37628,
	29.000,-0.37628,
	32.000,-0.37628,
	33.000,-0.60228,
	36.000,-0.60228,
	43.000,-0.60228,
	44.000,-0.65721,
	48.000,-0.65721,
	51.000,-0.65721,
	52.000,-0.51902,
	54.000,-0.51902,
	57.000,-0.51902,
	58.000,-0.80765,
	60.000,-0.80765,
	61.000,-0.80765,
	63.000,-0.83230,
	65.000,-0.83230,
};
extern LookupTable bassLoopFilterb1;
LookupTable bassLoopFilterb1(&bassLoopFilterb1_points[0], 18);

float getValueBassLoopFilterb1(float index){
	return bassLoopFilterb1.getValue(index);
}

double bassLoopFiltera1_points[19*2] = {
	24.000,-0.81486,
	26.000,-0.81486,
	27.000,-0.81147,
	29.000,-0.81147,
	32.000,-0.81147,
	33.000,-0.76078,
	36.000,-0.76078,
	43.000,-0.76078,
	44.000,-0.77075,
	48.000,-0.77075,
	51.000,-0.77075,
	52.000,-0.73548,
	54.000,-0.73548,
	57.000,-0.73548,
	58.000,-0.88810,
	60.000,-0.88810,
	61.000,-0.88810,
	63.000,-0.88537,
	65.000,-0.88537,
};
extern LookupTable bassLoopFiltera1;
LookupTable bassLoopFiltera1(&bassLoopFiltera1_points[0], 18);

float getValueBassLoopFiltera1(float index){
	return bassLoopFiltera1.getValue(index);
}