#' @title mp_info
#'
#' @description Provides current data on an MP for a particular constituency
#' @param constituency constituency name
#' @export
#' @return Dataframe of current MP information for constituency
#'
#'
mp_info<-function(constituency){
  csearch<-gsub(" ","+",constituency)
  url<-paste0("https://members.parliament.uk/members/Commons?SearchText=",
    csearch,
    "&PartyId=&Gender=Any&ForParliament=0&ShowAdvanced=False")
  PAGE<-xml2::read_html(url)
  #url<-"https://members.parliament.uk/members/Commons"
  p_selector_name<-".primary-info"
  s_selector_name<-".secondary-info"
  c_selector_name<-".card"
  p1<-rvest::html_nodes(PAGE,css = p_selector_name)
  p2<-rvest::html_text(p1)
  p3<-gsub("\r\n","",p2)
  PL<-length(p3)
  if(PL>1){
    CNAME<-rvest::html_nodes(PAGE,css= c_selector_name)
    CNAME2<-rvest::html_text(CNAME)
    CNAME3<-gsub("\r\n","",CNAME2)
    CNAME4<-trimws(CNAME3)
    CNAME5<-stringr::str_squish(CNAME4)
    CNAME5<-stringr::str_replace_all(CNAME5,"\\(|\\)", "")
    CNAME5<-iconv(CNAME5, "latin1", "ASCII", sub="")
    CNAME6<-strsplit(CNAME5, split="Conservative|Independent|Labour Co-op|Labour|Liberal Democrat|SNP|Scottish National Party|Sinn Fin")
    CLIST<-list()
    for (i in 1:length(CNAME6)){
      DF<-as.data.frame(t(as.data.frame(CNAME6[[i]])))
      colnames(DF)<-c("name","location")
      CLIST[[i]]<-DF
    }
    CNAME7<-purrr::map_df(CLIST,data.frame)
    CNAME8<-dplyr::mutate(CNAME7,order=1:length(CNAME7$name))
    CNAME8$location<-tolower(CNAME8$location)
    CNAME8$location<-trimws(CNAME8$location)
    check_name<-tolower(constituency)
    CNAME9<-dplyr::filter(CNAME8,location==check_name)
    ORD<-CNAME9$order
    p2<-rvest::html_text(p1[[ORD]])
    p3<-gsub("\r\n","",p2)
  }else{
    ORD<-1
    p2<-p2
    p3<-p3
  }
  mp_name<-gsub("  ","",p3)
  mp_nameA<-tolower(mp_name)
  mp_name2<- gsub(" *(ms)|(miss)|(dr)|(mrs)|(miss)|(mr)|(sir)|(Sir)$", "", mp_nameA)
  mp_name3<-trimws(mp_name2)
  first_name<-stringr::word(mp_name3, 1)
  surname<-tolower(stringr::word(mp_name,-1))

  s1<-rvest::html_nodes(PAGE,css = s_selector_name)
  s2<-rvest::html_text(s1[[ORD]])
  s3<-gsub("\r\n","",s2)
  party_name<-gsub("  ","",s3)

  c1<-rvest::html_nodes(PAGE,css = c_selector_name)
  c2<-rvest::html_attr(c1[[ORD]],"href")

  link_info<-paste0("https://members.parliament.uk",c2)
  link_split<-strsplit(c2,"/")
  link_split2<-unlist(link_split)
  member_id<-link_split2[[3]]

  hansard_link<-paste0("https://hansard.parliament.uk/search/MemberContributions?memberId=",
                       member_id,"&type=Spoken")

  career_url<-paste0("https://members.parliament.uk/member/",member_id,"/career")
  #constit_id

  ne_select<-".secondary-info"
  CP<-xml2::read_html(career_url)
  NE1<-rvest::html_nodes(CP,css = ne_select)
  NE2<-rvest::html_text(NE1)
  NE2<-NE2[[1]]
  NE2<-gsub("\r\n","",NE2)
  NE2<-trimws(NE2)
  NE3<-readr::parse_number(NE2)

  TS<-"div.card-list:nth-child(2) > a:nth-child(1) > div:nth-child(1) > div:nth-child(2) > div:nth-child(1) > div:nth-child(1) > div:nth-child(1)"

  TS1<-rvest::html_nodes(CP,css =TS)
  TS2<-rvest::html_text(TS1)
  TS3<-gsub("\r\n","",TS2)
  TS4<-trimws(TS3)
  time_split<-stringr::str_split(TS4,"-")
  time_split<-unlist(time_split)
  #first_time
  first1<-time_split[[1]]
  first1<-trimws(first1)
  first_date<-as.Date(first1, format = "%d %B %Y")

  first_year<-lubridate::year(first_date)
  first_month<-lubridate::month(first_date)

  #last_time
  last1<-time_split[[2]]
  last1<-trimws(last1)

  if (last1=="Present"){
    last_date<-"current"
    last_year<-"current"
    last_month<-"current"
  }else{
    last_date<-as.Date(last1, format = "%d %B %Y")
    last_year<-lubridate::year(first_date)
    last_month<-lubridate::month(first_date)
  }

  #committee
  com_select<-"div.card > div:nth-child(1) > div:nth-child(1) > div:nth-child(1)"
  com1<-rvest::html_nodes(CP,css =com_select)
  com2<-rvest::html_text(com1)
  com3<-gsub("\r\n","",com2)
  com3<-trimws(com3)
  com3<-unique(com3)
  com4<-stringr::str_c(com3,collapse='/')

  #status
  ele_url<-paste0("https://members.parliament.uk/member/",member_id,"/electionresult")
  stat_select<-".content > div:nth-child(1)"
  EP<-xml2::read_html(ele_url)
  ele1<-rvest::html_nodes(EP,css =stat_select)
  ele2<-rvest::html_text(ele1)
  ele3<-gsub("\r\n","",ele2)
  ele3<-trimws(ele3)



  first_g<-gender::gender(names=first_name,
                          method="ssa",year="2012")
  gender1<-first_g$gender
  if(purrr::is_empty(gender1)==TRUE){
    gender1<-"NA"
  }else{gender1<-gender1}

  #constituency2<-gsub(",","",constituency)

  con2<-gsub(" ","_",constituency)
  wiki<-paste0("https://en.wikipedia.org/wiki/",
               con2,"_(UK_Parliament_constituency)")
  webpage <- xml2::read_html(wiki)

  #GG<-".infobox > tbody:nth-child(1) > tr:nth-child(10) > td:nth-child(2) > a:nth-child(1)"
  #GG<-".infobox > tbody:nth-child(1) > tr:nth-child(11) > td:nth-child(2)"
  GG<-".infobox > tbody:nth-child(1) > tr:nth-child(11) > td:nth-child(2) > a:nth-child(1)"
  #CS selector
  #.infobox > tbody:nth-child(1) > tr:nth-child(8) > td:nth-child(2)

  mp1<-rvest::html_nodes(webpage,css = GG)
  LEN_MP<-length(mp1)
  if (LEN_MP==0){
    GA<-".infobox > tbody:nth-child(1) > tr:nth-child(8) > td:nth-child(2) > a:nth-child(1)"
    mpA<-rvest::html_nodes(webpage,css = GA)
    mp2<-rvest::html_attr(mpA,"href")

  }else{mp2<-rvest::html_attr(mp1,"href")}

  if(purrr::is_empty(mp2)){
    GB<-".infobox > tbody:nth-child(1) > tr:nth-child(10) > td:nth-child(2) > a:nth-child(1)"
    mpB<-rvest::html_nodes(webpage,css = GB)
    mp2<-rvest::html_attr(mpB,"href")
  }else{mp2<-mp2}

  if(purrr::is_empty(mp2)){
    Gemp<-".infobox > tbody:nth-child(1) > tr:nth-child(6) > td:nth-child(2) > a:nth-child(1)"
    mpEMP<-rvest::html_nodes(webpage,css = Gemp)
    mp2<-rvest::html_attr(mpEMP,"href")
  }else{mp2<-mp2}

  if(purrr::is_empty(mp2)){
    Gfix<-".infobox > tbody:nth-child(1) > tr:nth-child(9) > td:nth-child(2) > a:nth-child(1)"
    mpFIX<-rvest::html_nodes(webpage,css = Gfix)
    mp2<-rvest::html_attr(mpFIX,"href")
  }else{mp2<-mp2}

  CHECK1<-stringr::str_detect(mp2,"(UK_Parliament_constituency)")
  if(CHECK1==TRUE){
    GC<-".infobox > tbody:nth-child(1) > tr:nth-child(9) > td:nth-child(2) > a:nth-child(1)"
    mpC<-rvest::html_nodes(webpage,css = GC)
    mp2<-rvest::html_attr(mpC,"href")
  }else{mp2<-mp2}

  if(purrr::is_empty(mp2)){
    GD<-".infobox > tbody:nth-child(1) > tr:nth-child(7) > td:nth-child(2) > a:nth-child(1)"
    mpD<-rvest::html_nodes(webpage,css = GD)
    mp2<-rvest::html_attr(mpD,"href")
  }else{mp2<-mp2}

  CHECK2<-stringr::str_detect(mp2,"United_Kingdom_general_election")
  if(CHECK2==TRUE){
    GE<-".infobox > tbody:nth-child(1) > tr:nth-child(9) > td:nth-child(2) > a:nth-child(1)"
    mpE<-rvest::html_nodes(webpage,css = GE)
    mp2<-rvest::html_attr(mpE,"href")
  }else{mp2<-mp2}

  CHECK3<-stringr::str_detect(mp2,"United_Kingdom_general_election")
  if(CHECK3==TRUE){
    GF<-".infobox > tbody:nth-child(1) > tr:nth-child(10) > td:nth-child(2) > a:nth-child(1)"
    mpF<-rvest::html_nodes(webpage,css = GF)
    mp2<-rvest::html_attr(mpF,"href")
  }else{mp2<-mp2}

  CHECK4<-stringr::str_detect(mp2,"(UK_Parliament_constituency)")
  if(CHECK4==TRUE){
    GG<-".infobox > tbody:nth-child(1) > tr:nth-child(8) > td:nth-child(2) > a:nth-child(1)"
    mpG<-rvest::html_nodes(webpage,css = GG)
    mp2<-rvest::html_attr(mpG,"href")
  }else{mp2<-mp2}

  CHECK5<-stringr::str_detect(mp2,"(Parliament_of_Scotland_constituency)")
  CHECK5a<-purrr::is_empty(CHECK5)
  if(CHECK5a==TRUE){
    CHECK5<-FALSE
  }else{CHECK5<-CHECK5}

  if(CHECK5==TRUE){
    Gscot<-".infobox > tbody:nth-child(1) > tr:nth-child(9) > td:nth-child(2) > a:nth-child(1)"
    mpscot<-rvest::html_nodes(webpage,css = Gscot)
    mp2<-rvest::html_attr(mpscot,"href")
  }else{mp2<-mp2}

  if(purrr::is_empty(mp2)){
    LR1<-".infobox > tbody:nth-child(1) > tr:nth-child(7) > td:nth-child(2) > a:nth-child(1)"
    mpLR<-rvest::html_nodes(webpage,css = LR1)
    mp2<-rvest::html_attr(mpLR,"href")
  }else{mp2<-mp2}

  CHECK6<-stringr::str_detect(mp2,"National_Assembly_for_Wales_electoral_region")
  CHECK6a<-purrr::is_empty(CHECK6)
  if(CHECK6a==TRUE){
    CHECK6<-FALSE
  }else{CHECK6<-CHECK6}

  if(CHECK6==TRUE){
    Gwelsh<-".infobox > tbody:nth-child(1) > tr:nth-child(7) > td:nth-child(2) > a:nth-child(1)"
    mpwelsh<-rvest::html_nodes(webpage,css = Gwelsh)
    mp2<-rvest::html_attr(mpwelsh,"href")
  }else{mp2<-mp2}

  mp_link1<-paste0("https://en.wikipedia.org/",
                   mp2)

  mppage <- xml2::read_html(mp_link1)
  mp_node<-rvest::html_nodes(mppage,"table.vcard")
  mp_tab<-rvest::html_table(mp_node,header=F,fill = TRUE)
  data_tab<-mp_tab[[1]]
  DOB<-dplyr::filter(data_tab,X1=="Born")
  DOB1<-gsub(" ","",DOB$X2)
  DOB2<-stringr::str_split(DOB1,"[(]",
                          simplify = T)
  DOB3<-stringr::str_split(DOB2,"[)]",
                          simplify = T)
  DOB_LEN<-sum(dim(DOB3))
  if (DOB_LEN>4){
    DOB_data<-DOB3[2,1]
    #ymd
    DOB_split<-stringr::str_split(DOB_data,"-")
    DOB_split<-unlist(DOB_split)
    birth_year<-DOB_split[[1]]
    birth_month<-DOB_split[[2]]
    birth_day<-DOB_split[[3]]
  }else if(DOB_LEN==0){
    DOB_data2<-"NA"
    DOB_data<-"NA"
    birth_year<-"NA"
    birth_month<-"NA"
    birth_day<-"NA"
  }else{
    dd<-DOB3[1,1]
    dd2<-c(dd)
    DOB_dataA<-stringr::str_extract_all(dd2, "\\d+")
    DOB_data2<-DOB_dataA[[1]]
    if (purrr::is_empty(DOB_data2)){
      DOB_data2<-"NA"
      birth_year<-"NA"
    }else{
      #DOB_data<-DOB_data2
      birth_year<-DOB_data2[[1]]
      }

    birth_month<-"NA"
    birth_day<-"NA"
    DOB_data<-as.character(birth_year)

  }

  if (purrr::is_empty(DOB_data)){
    DOB_data<-"NA"
  }else{DOB_data<-DOB_data}

  if (purrr::is_empty(birth_year)){
    birth_year<-"NA"
  }else{birth_year<-DOB_data}



  nat1<-dplyr::filter(data_tab,X1=="Nationality")
  nat2<-nat1$X2
  CN<-purrr::is_empty(nat2)
  if (CN==TRUE){
    nat3<-NA
  }else{nat3<-nat2}

  am1<-dplyr::filter(data_tab,X1=="Alma mater")
  am2<-am1$X2
  CHECK<-purrr::is_empty(am2)
  if (CHECK==TRUE){
    am3<-"NA"
  }else{am3<-am2}
  DATA<-tibble::tibble(constituency=constituency,
                       constituency_status=ele3,
                       mp_name=mp_name,
                       member_id=member_id,
                       mp_link=link_info,
                       first_name=first_name,
                       surname=surname,
                       party=party_name,
                       first_date=first_date,
                       first_month=first_month,
                       first_year=first_year,
                       last_date=last_date,
                       last_month=last_month,
                       last_year=last_year,
                       number_times_elected=NE3,
                       membership_post_gov_opp_committee=com4,
                       gender=gender1,
                       dob=DOB_data,
                       birth_year=birth_year,
                       birth_month=birth_month,
                       birth_day=birth_day,
                       natioanlity=nat3,
                       alma_mater=am3,
                       hansard_link=hansard_link
                       )
  return(DATA)
}
