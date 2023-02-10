#function for creating crosswalk
crosswalk<- function(df){
  df1<- df%>% as_tibble()%>%
    mutate(
      SG1= PZ01+ PZ03+PZ07+PZ08,
      SG2= PZ09+ PZ12,
      SG3= PZ02+ PZ05+PZ06+PZ10+PZ11+ PZ14+PZ15+PZ16,
      SG4= PZ04+ PZ25,
      SG5= PZ13+ PZ21+PZ31+PZ34+PZ35,
      SG6= PZ17+ PZ18+PZ19+PZ20+PZ22+PZ24,
      SG7= PZ32+ PZ36+PZ41+PZ43+PZ49+ PZ52+PZ53+PZ67,
      SG8= PZ40+ PZ47+PZ48+PZ50+PZ54 ,
      SG9= PZ42+ PZ45+PZ56+PZ61,
      SG10= PZ26+ PZ30+PZ33+PZ37+PZ44+ PZ59+PZ60+PZ63+PZ65+PZ66,
      SG11= PZ23+ PZ27+PZ28+PZ29+PZ38+ PZ39+PZ46+PZ51+ PZ55+ PZ57+ PZ58+PZ62+ PZ64+ PZ68)
  
return(df1)}

#function for testing crosswalk 

crosswalk_test<- function(df,df1,df2){
  df<- df%>% as_tibble()%>%
    mutate(
      SG1= df1$SG1==df2$SG1,
      SG2= df1$SG2==df2$SG2,
      SG3= df1$SG3==df2$SG3,
      SG4= df1$SG4==df2$SG4,
      SG5= df1$SG5==df2$SG5,
      SG6= df1$SG6==df2$SG6,
      SG7= df1$SG7==df2$SG7,
      SG8= df1$SG8==df2$SG8,
      SG9= df1$SG9==df2$SG9,
      SG10= df1$SG10==df2$SG10,
      SG11= df1$SG11==df2$SG11,
     )
  return(df)
}



#crosswalking mapping 
input$SG1<- input$PZ01+ input$PZ03+input$PZ07+input$PZ08
input$SG2<- input$PZ09+ input$PZ12
input$SG3<- input$PZ02+ input$PZ05+input$PZ06+input$PZ10+input$PZ11+ input$PZ14+input$PZ15+input$PZ16
input$SG4<- input$PZ04+ input$PZ25
input$SG5<- input$PZ13+ input$PZ21+input$PZ31+input$PZ34+input$PZ35
input$SG6<- input$PZ17+ input$PZ18+input$PZ19+input$PZ20+input$PZ22+input$PZ24
input$SG7<- input$PZ32+ input$PZ36+input$PZ41+input$PZ43+input$PZ49+ input$PZ52+input$PZ53+input$PZ67
input$SG8<- input$PZ40+ input$PZ47+input$PZ48+input$PZ50+input$PZ54 
input$SG9<- input$PZ42+ input$PZ45+input$PZ56+input$PZ61
input$SG10<- input$PZ26+ input$PZ30+input$PZ33+input$PZ37 + input$PZ44+ input$PZ59+input$PZ60+input$PZ63+input$PZ65+input$PZ66
input$SG11<- (input$PZ23+ input$PZ27+input$PZ28+input$PZ29+ input$PZ38+ input$PZ39+input$PZ46+input$PZ51+ input$PZ55+ input$PZ57+
                input$PZ58+input$PZ62+ input$PZ64+ input$PZ68)
