
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}


packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice","cowplot","gtable","ggrepel")
       
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

maindir = dirname(rstudioapi::getSourceEditorContext()$path)

source("../Queries/readSQL.R")


datasource_id = 19

hh <- data.frame()
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
hh_sql <- gsub("ds_id", datasource_id,hh_sql)
hhquery<-sqlQuery(channel,hh_sql,stringsAsFactors = FALSE)
hhquery$datasource_id = datasource_id
hh <- rbind(hh,hhquery)
odbcClose(channel)


hh$geozone[hh$geotype =="region"]<- "Region"
hh$geozone <- gsub("\\*","",hh$geozone)
hh$geozone <- gsub("\\-","_",hh$geozone)
hh$geozone <- gsub("\\:","_",hh$geozone)

colnames(hh)[colnames(hh)=="yr_id"] <- "Year"
hh$datasource_id = factor( hh$datasource_id) 

# region plots
hh_region<-subset(hh, geotype=="region")


# jursidiction plots

hh_jur<-subset(hh, geotype=="jurisdiction")

jur_list = unique(hh_jur[["geozone"]])

results<-"plots\\hh_variable_comparison\\PopvsHH_19only2\\"

ifelse(!dir.exists(file.path(maindir,results)), 
       dir.create(file.path(maindir,results), 
                  showWarnings = TRUE, recursive=TRUE),0)
# # library(ggrepel)
# # for(i in jur_list) {
# for(i in jur_list[1:2]) {
#   plotdat <- subset(hh,geozone==i & datasource_id %in% c(19))
#   plotdat$yr_id = plotdat$Year
#   plotdat$Year = as.factor(plotdat$Year)
#   plotdat$YearHHpop <- paste(plotdat$Year,plotdat$Household_Pop,sep=',')
#   #plot <- ggplot(data=plotdat, aes(y=Num_Households, x=Household_Pop,label=Year)) + 
#   #plot <- ggplot(data=plotdat, aes(y=Persons_per_Household, x=Household_Pop,label=Year)) + 
#   #plot <- ggplot(data=plotdat, aes(y=Persons_per_Household, x=Num_Households,label=Year)) +
#   plot <- ggplot(data=plotdat, aes(y=Persons_per_Household, x=Num_Households,label=YearHHpop)) +
#     #geom_point(aes(size=Persons_per_Household)) + geom_line() +
#     geom_point() + geom_line() +
#     #scale_size(range=c(2,3.6),expand=c(2,0),breaks=c(2,2.2,2.4,2.6,2.8,3.0,3.2,3.4,3.6),labels=c(2,2.2,2.4,2.6,2.8,3.0,3.2,3.4,3.6),guide="legend") +
#     # scale_size(range = c(2.4, 2.6)) +
#     # geom_text(aes(label=Year),hjust=0.5, vjust=0.5) +
#     geom_text_repel() +
#     #geom_label_repel(aes(label = Year),
#     #                 box.padding   = 0.35, 
#     #                 point.padding = 0.5,
#     #                 segment.color = 'grey50') +
#     theme(legend.position = "bottom") +
#     #labs(subtitle="Household Pop, Households, and Household Size", 
#     #     x="Household Population", 
#     #     y="Number of Households", 
#     #     title=i
#          #caption = paste("Source: Demographic Warehouse Datsource id=", 
#          #                toString(unique(plotdat$datasource_id),sep=''))
#     # ) +
#     labs(subtitle="Household Pop, Households, and Household Size", 
#          x="Num_Households", 
#          y="Persons_per_Household", 
#          title=i
#          #caption = paste("Source: Demographic Warehouse Datsource id=", 
#          #                toString(unique(plotdat$datasource_id),sep=''))
#     ) +
#     # scale_y_continuous(limits=c(0, 8)) +
#     scale_y_continuous(limits=c(2, 3.6)) +
#     theme(plot.subtitle=element_text(size=12, hjust=0.5, face="italic", color="black"))
#   output_table = plotdat[,c("Year","Num_Households","Household_Pop","Persons_per_Household")]
#   # t1 = gridExtra::tableGrob(output_table)
#   
#   
#   
#   tt <- ttheme_default(colhead = 
#                          # first unit is the wdith, and second the height
#                          list(padding=unit.c(unit(4, "mm"), unit(10, "mm"))))
#   tbl <- tableGrob(output_table, rows=NULL, theme=tt)
#   title <- textGrob(paste("HH Pop and Size, ds id ",datasource_id,sep=""),
#                     gp=gpar(fontsize=16))
#   title <- textGrob('',
#                     gp=gpar(fontsize=16))
#   padding <- unit(5,"mm")
#   table <- gtable_add_rows(
#     tbl, 
#    heights = grobHeight(title) + padding,
#     pos = 0)
#   table <- gtable_add_grob(
#     table, 
#    title, 
#     1, 1, 1, ncol(table))
#   output<-grid.arrange(plot,table,as.table=TRUE,nrow = 2,#layout_matrix=lay,
#                        bottom = textGrob(paste("Source:", 
#                                                "SR14: demographic warehouse: fact.population table ",datasource_id,sep=''),
#                                          x = .01, y = 0.5, just = 'left', gp = gpar(fontsize = 6.5)))
#   ggsave(output, width=6, height=8, dpi=100, 
#          file= paste(results,'hh_hhpop_hhsize ',
#                      plotdat$geozone[1], ".png", sep=''))
#   
# }
 
names(hh) <- c("Year","geotype","geozone","Num_Households","Household_Pop","Persons_per_Household","ds_id")


for(i in jur_list[1:2]) {
  plotdat <- subset(hh,geozone==i & datasource_id %in% c(19))
  plotdat$yr_id = plotdat$Year
  plotdat$Year = as.factor(plotdat$Year)
  # plotdat$YearHHpop <- paste(plotdat$Year,plotdat$Household_Pop,sep=',')
  plotdat$HH_HHs <- paste(plotdat$Num_Households,plotdat$Persons_per_Household,sep=',')

  plot <- ggplot(data=plotdat, aes(y=Persons_per_Household, x=Num_Households,label=HH_HHs)) +
    facet_grid(Year ~ Household_Pop)+
    geom_point() + geom_line() +
    geom_text_repel() +
    theme(legend.position = "bottom") +
    labs(subtitle="Household Pop, Households, and Household Size",
         x="Num_Households",
         y="Persons_per_Household",
         title=i
    ) +
    scale_y_continuous(limits=c(2, 3.6)) +
    theme(plot.subtitle=element_text(size=12, hjust=0.5, face="italic", color="black"))


  title <- textGrob(paste("HH Pop and Size, ds id ",datasource_id,sep=""),
                    gp=gpar(fontsize=16))
  title <- textGrob('',
                    gp=gpar(fontsize=16))

  ggsave(plot, width=10, height=8, dpi=100,
         file= paste(results,'hh_hhpop_hhsize ',
                     plotdat$geozone[1], ".png", sep=''))

}


long <- reshape2::melt(plotdat, id.vars = c("Year","geotype","geozone","ds_id","yr_id","HH_HHs"))
long$variable2 = factor(long$variable, levels=c("Household_Pop","Num_Households", "Persons_per_Household"))
plot <- ggplot(data=long, aes(y=value, x=Year,group=variable2)) + geom_point() + geom_line()  + 
  #facet_grid(variable2 ~ .,scales="free_y")
  geom_text(aes(label=value),size = 4, hjust=1, vjust=-0.7) +
  facet_wrap( variable2 ~., ncol=1,scales="free_y") +
  theme(strip.text.x = element_text(size=15), 
        axis.text.x = element_text(size=12), 
        axis.text.y = element_text(size=12),
        axis.title.x = element_blank(),
        axis.title.y = element_blank()) +
  ggtitle(paste(long$geozone[1],"_ds",datasource_id,sep="")) +
  theme(plot.title = element_text(size = 18, face = "bold"))

ggsave(plot, width=9, height=16, dpi=100, 
       file= paste(results,'hh_hhpop_hhsize ',
                   plotdat$geozone[1], ".png", sep=''))


df = mtcars
ggplot(data = df, aes(x = mpg, y = hp)) + 
  geom_point(color='blue') +
  geom_smooth(method = "lm", se = FALSE)

df = subset(long,variable %in% c('Household_Pop','Num_Households'))

ggplot(data = df, aes(x = Year, y = value)) + 
  geom_point(color='blue') +
  geom_smooth(method = "lm", se = FALSE)





for(i in jur_list[1:2]) {
  plotdat <- subset(hh,geozone==i & datasource_id %in% c(19))
  plotdat$yr_id = plotdat$Year
  plotdat$Year = as.factor(plotdat$Year)
  #plot <- ggplot(data=plotdat, aes(y=Num_Households, x=Household_Pop,label=Year)) + 
  plot <- ggplot(data=plotdat, aes(x=Persons_per_Household,label=Year)) + 
    #geom_point(aes(size=Persons_per_Household)) + geom_line() +
  geom_line(aes(y=Household_Pop)) +
  geom_point(aes(y=Household_Pop)) +
  geom_text(aes(label=Year),hjust=0.5, vjust=0.5) +
  geom_line(aes(y= Num_Households)) +
  geom_point(aes(y= Num_Households)) + 
    ggsave(plot, width=6, height=8, dpi=100, 
           file= paste(results,'hh_hhpop_hhsize ',
                       plotdat$geozone[1], ".png", sep=''))
    
    }

results<-"plots\\hh_variable_comparison\\PopvsHH_19cpaonly\\"

ifelse(!dir.exists(file.path(maindir,results)), 
       dir.create(file.path(maindir,results), 
                  showWarnings = TRUE, recursive=TRUE),0)
hh_cpa<-subset(hh, geotype=="cpa")
cpa_list<-unique(hh_cpa$geozone)
#for(i in cpa_list) {
for(i in cpa_list) {
  plotdat <- subset(hh,geozone==i & datasource_id %in% c(19))
  plotdat$yr_id = plotdat$Year
  plotdat$Year = as.factor(plotdat$Year)
  cpa_name = i
  cpa_name = gsub("\\*","",cpa_name)
  cpa_name = gsub("\\-","_",cpa_name)
  cpa_name = gsub("\\:","_",cpa_name)
  gg <- ggplot(data=plotdat, aes(x=Num_Households, y=Household_Pop)) + 
    # geom_point(aes(col=datasource_id,size=Persons_per_Household)) + geom_line(aes(col=datasource_id)) +
    geom_point(aes(col=datasource_id,size=Persons_per_Household)) + geom_line(aes(col=datasource_id)) +
    # scale_size_continuous(limits=c(0,4)) +
    labs(subtitle="Household Population vs Number of Households", 
         y="Household Population", 
         x="Number of Households", 
         title=i, 
         caption = paste("Source: Demographic Warehouse Datsource id=", 
                         toString(unique(plotdat$datasource_id),sep=''))) 
  ggsave(gg, file=paste(results,i,"_hhpop",
                        gsub(", ","_",toString(unique(plotdat$datasource_id))),".png",sep=""),
         width=12,height=8,dpi=100)
  output_table = plotdat[,c("Year","Num_Households","Household_Pop","Persons_per_Household","datasource_id")]
  output_table13 = subset(output_table,datasource_id==13)
  output_table13$datasource_id <- NULL
  output_table19 = subset(output_table,datasource_id==19)
  output_table19$datasource_id <- NULL
  outtbl = merge(output_table13,output_table19,by='Year',all=TRUE,suffixes = c("(13)","(19)"))
  outtbl <- outtbl[c(1, 2, 5, 3,  6, 4, 7)] # reorder columns
  t1 = gridExtra::tableGrob(outtbl)
  title <- textGrob(i,gp=gpar(fontsize=50))
  padding <- unit(5,"mm")
  table <- gtable_add_rows(
    t1, 
    heights = grobHeight(title) + padding,
    pos = 0)
  table <- gtable_add_grob(
    table, 
    title, 
    1, 1, 1, ncol(table))
  h = grid::convertHeight(sum(table$heights), "in", TRUE)
  w = grid::convertWidth(sum(table$widths), "in", TRUE)
  cpa_name
  ggplot2::ggsave(file= paste(results, cpa_name, 'data', 
                              gsub(", ","_",toString(unique(plotdat$datasource_id))),
                              ".png", sep=''), table, width=w, height=h)
  
}



# plots
# function for jur and cpa plots
hhhhphhz <- function(plotdat) {
  lowerlimit = 40000
  upperlimit = 106000
  scale_change=''
  data_long <- melt(plotdat,id.vars=c("yr_id","geozone"),
                    measure.vars=c("median_inc","med_inc_reg1"),
                    variable.name="source",value.name="median_income")
  if (NROW(na.omit(data_long[(data_long[,'median_income']<lowerlimit),]))) {
    lowerlimit = min(data_long$median_income)
    scale_change='\nNote: scale change'
  }
  if (NROW(na.omit(data_long[(data_long[,'median_income']>upperlimit),]))) {
    upperlimit = max(data_long$median_income)
    scale_change='\nNote: scale change'
  }
  plot<- ggplot(plotdat, aes(x=yr_id))+
    geom_line(aes(y=median_inc,  color=paste("id ",datasource_id,' ',plotdat$geozone[1],sep='')),size=1.2) +
    geom_point(aes(y=median_inc, color=paste("id ",datasource_id,' ',plotdat$geozone[1],sep='')), size=3, alpha=0.8) +
    geom_line(aes(y= med_inc_reg1, color=paste("Region")),linetype="dashed",size=1.2) +
    geom_point(aes(y= med_inc_reg1, color=paste("Region")), size=3, alpha=0.8) +
    scale_y_continuous(labels = comma, limits=c(lowerlimit,upperlimit)) +
    labs(title=paste(plotdat$geozone[1], " Household Median Income ",sep=""), 
         y="Median Income", x="Year",
         subtitle=paste('SR14 datasource id ',datasource_id,
                        scale_change,sep='')) +
    theme_bw(base_size = 12)+
    theme(legend.position = "bottom",
          legend.title=element_blank()) +
    theme(axis.text.x=element_text(size=14,angle=0)) +
    theme(axis.title.x=element_text(size=16,angle=0, hjust=0.5, vjust=1)) +
    theme(axis.text.y=element_text(size=14,angle=0)) +
    theme(axis.title.y=element_text(size=16,angle=90)) +
    theme(plot.title = element_text(hjust = 0.5,size=18,face="bold")) +
    theme(plot.subtitle=element_text(size=14, hjust=0.5, face="italic", color="black"))
  
  output_table<-data.frame(plotdat$yr_id,plotdat$median_inc,
                           plotdat$med_inc_reg1,plotdat$Num_Households)
  sr14_colname1 = paste("Median Income ","\n",plotdat$geozone[1],sep=" ")
  sr14_colname_region1 = paste("Median Income ","\nRegion",sep=" ")
  setnames(output_table, 
           old=c("plotdat.yr_id","plotdat.median_inc",
                 "plotdat.med_inc_reg1","plotdat.Num_Households"),
           new=c("Year",sr14_colname1,sr14_colname_region1,"num_hh"))
  tt <- ttheme_default(colhead = 
                         # first unit is the wdith, and second the height
                         list(padding=unit.c(unit(4, "mm"), unit(10, "mm"))))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  title <- textGrob(paste("HH Median Income, ds id ",datasource_id,sep=""),
                    gp=gpar(fontsize=16))
  padding <- unit(5,"mm")
  table <- gtable_add_rows(
    tbl, 
    heights = grobHeight(title) + padding,
    pos = 0)
  table <- gtable_add_grob(
    table, 
    title, 
    1, 1, 1, ncol(table))
  output<-grid.arrange(plot,table,as.table=TRUE,nrow = 2,#layout_matrix=lay,
                       bottom = textGrob(paste("Sources:", 
                                               "\nSR14: demographic warehouse: 
                                               dbo.compute_median_income_all_zones ",datasource_id,sep=''),
                                         x = .01, y = 0.5, just = 'left', gp = gpar(fontsize = 6.5)))
  ggsave(output, width=6, height=8, dpi=100, 
         file= paste(results,'median income ',
                     plotdat$geozone[1], ".png", sep=''))
}



folder_name = paste('cpa_ds',datasource_id,sep='')
results<-paste("plots\\hh_variable_comparison\\",folder_name,"\\",sep='')
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)
cpa_list<-unique(hh_cpa$geozone)
#for(i in 1:length(cpa_list)) { 
for(i in 1:5) {
  cpadat <- subset(hh,geozone==cpa_list[i] & datasource_id %in% c(19))
  cpadat$yr_id =  cpadat$Year
  cpadat$Year = as.factor( cpadat$Year)
  cpadat$geozone = gsub("\\*","",cpadat$geozone)
  cpadat$geozone = gsub("\\-","_",cpadat$geozone)
  cpadat$geozone = gsub("\\:","_",cpadat$geozone)
  hhhhphhz(cpadat)
}
