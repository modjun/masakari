#coding: utf-8

require 'sinatra'
require 'haml'

set :public_folder, File.dirname(__FILE__) + '/static'

# IEがクソ過ぎてこう書かないと文字化ける(METAタグ単独は無駄)
get '/' do
	@base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
	content_type :html, :charset => 'utf-8'
	haml :index, :charset => 'utf-8'
end

get '/s' do
	content_type :js
	locals = {"shussha_sub" => 20, "taisha_sub" => 20, "kyukei_time" => "0130"}.merge(params)
	erb :s, :locals => locals
end

__END__

@@ index
%html
	%head
		%meta{:charset => 'utf-8'}
		%script{:type => 'text/javascript', :src => 'https://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js'}

	%body
		%h1 Masakari
		%h2 Masakariとは
		Masakariは、勤太郎の入力補助ツールです。以下の機能を持ちます。
		%dl
			%dt 自動入力
			%dd 出社時間・退社時間・実働時間を、入館時間・退館時間から自動入力します。すでに入力されている場合は自動入力は行いません。休日へは自動入力は行いません。
			%dt 自動変更
			%dd 出社時間・退社時間を変更した場合、自動的に実労時間を再計算します。
				
		%h2 Masakariの使い方
		以下を入力してボタンを押下し、出てきたリンクをブックマークしてください。
		%br
		勤太郎を開いた状態で、登録したブックマークを開くと、Masakariが実行されます。
		%br
		%label
			出社差分
			%input{:type => 'text', :id => 'shussha_sub'}
		%br
		%label
			休憩時間
			%input{:type => 'text', :id => 'kyukei_time'}
		%br
		%label
			退社差分
			%input{:type => 'text', :id => 'taisha_sub'}
		%br
		%input{:type => 'button', :id => "go", :value => "GO"}
		%br
		%div.result
		
		%h2 特記事項
		%ul
			%li Masakariは、<a href="http://kintarou.herokuapp.com/">筋太郎</a>のアレンジです。吉田氏に敬意を表します。
			%li Masakariの利用は、自己責任でお願いいたします。
			%li ブックマークをクリックしても、正しくMasakariが実行されないことがあります（ライブラリのロード遅延が原因です）。その場合、もう一度ブックマークをクリックしてみてください。
		
		:javascript
			$($("#go").click(function(){
				var a = document.createElement("a");
				a.href = "javascript:(function(){document.body.appendChild(document.createElement('script')).src='#{@base_url}" + "/s?shussha_sub=" + $("#shussha_sub").val() + "&taisha_sub=" + $("#taisha_sub").val() + "&break_time=" + $("#kyukei_time").val() + "';})();"
				a.appendChild(document.createTextNode("link"));
				$(".result").html(a);
			}));

@@ s

var params = {shussha_sub: <%=shussha_sub%>, kyukei: "<%=kyukei_time%>", taisha_sub:<%=taisha_sub%>};
var frameDocument, nyukan, shussha, taikan, taisha, tr, jitsudou, kyuka;

String.prototype.padLeft = function(length, character) {
	return new Array(length - this.length + 1).join(character || "0") + this;
};

function loadScript(url) {
	var s = document.createElement("script");
	s.src = url;
	document.getElementsByTagName("head")[0].appendChild(s);
}

function calcDiffHoursString(time1, time2) {
	var hour, minute, workingtime_in_min;	
	workingtime_in_min = moment(time2, ["HHmm"]).diff(moment(time1, ["HHmm"]), "minutes");
	hour = Math.floor(workingtime_in_min / 60);
	minute = workingtime_in_min % 60;
	return String(hour).padLeft(2, "0") + String(minute).padLeft(2, "0");
}

function insertJitsudou(e) {
	var jitsudou_hirunuki, jitsudou_raw;
	var i = e.data.i;
	if (shussha[i].val()!==""&&taisha[i].val()!=="") {
		jitsudou_raw = calcDiffHoursString(shussha[i].val().padLeft(4, "0"), taisha[i].val().padLeft(4, "0"));
		jitsudou_hirunuki = calcDiffHoursString(params.kyukei, jitsudou_raw);
		jitsudou_hirunuki = jitsudou_hirunuki.slice(0, 3) + "0";
		jitsudou[i].val(jitsudou_hirunuki);
	}
}

loadScript("https://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js");
loadScript("http://cdnjs.cloudflare.com/ajax/libs/moment.js/2.0.0/moment.min.js");

setTimeout(function(){
	frameDocument = $("html", window.parent.frames[1].document);
	tr = $("table[border=3] tr", frameDocument);
	nyukan = [];
	taikan = [];
	taisha = [];
	shussha = [];
	jitsudou = [];
	kyuka = [];
	
	tr.each(function(m) {
		if ($("td", this).eq(0).text() === "休暇区分") {
			$("td > select", this).each(function(i) {
				kyuka.push($(this).val() !== "Holiday_1");
			});
		}

		if ($("td", this).eq(0).text() === "入館時間") {
			$("td:not(.HdCels2)", this).each(function(i) {
				var tmp;
				tmp = $(this).text();
				if (tmp.match(/\d{4}/i)) {
					nyukan.push(tmp);
				} else {
					nyukan.push(null);
				}
			});
		}
		if ($("td", this).eq(0).text() === "退館時間") {
			$("td:not(.HdCels2)", this).each(function(i) {
				var tmp;
				tmp = $(this).text();
				if (tmp.match(/\d{4}/i)) {
					return taikan.push(tmp);
				} else {
					return taikan.push(null);
				}
			});
		}
		if ($("td", this).eq(0).text() === "出社時間") {
			$("td > input", this).each(function(i) {
				shussha.push($(this));
				$(this).change({i:i}, insertJitsudou);
				if ($(this).val() === "" && !kyuka[i] && nyukan[i] !== null) {
					$(this).val(moment(nyukan[i], "HHmm").add({minutes:params.shussha_sub}).format("HHmm").slice(0, 3) + "0");
				}
			});
		}
		if ($("td", this).eq(0).text() === "退社時間") {
			$("td > input", this).each(function(i) {
				taisha.push($(this));
				$(this).change({i:i}, insertJitsudou);
			});
		}
		if ($("td", this).eq(0).text() === "実働時間") {
			$("td > input", this).each(function(i) {
				jitsudou.push($(this));
			});
		}
	});
	for (var i=0; i < taisha.length; ++i) {
		if (taisha[i].val() === "" && !kyuka[i]) {
			var taisha_time;
			if (taikan[i] !== null) {
				taisha_time = moment(taikan[i], "HHmm").subtract({minutes:params.taisha_sub}).format("HHmm");
				taisha_time = taisha_time.slice(0, 3) + "0";
				taisha[i].val(taisha_time);
			}
			
		}
		taisha[i].change();
	}}
	,1000
);
