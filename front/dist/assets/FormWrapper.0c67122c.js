import{n as u}from"./index.2e04400c.js";var o=function(){var e=this,t=e.$createElement,r=e._self._c||t;return r("form",{on:{submit:function(a){return a.preventDefault(),e.handleSubmit.apply(null,arguments)}}},[r("p",[e._v(e._s(e.title))]),e._t("default"),e.error!==null?r("p",{staticClass:"error-message"},[e._v(" "+e._s(e.error)+" ")]):e._e(),r("input",{attrs:{type:"submit",value:"Submit"}})],2)},s=[];const i={props:{title:{type:String,required:!0},submitCallback:{type:Function,required:!0}},data:function(){return{error:null}},methods:{handleSubmit:async function(){try{await this.submitCallback()}catch(e){console.error(e),this.error=e}}}},n={};var l=u(i,o,s,!1,_,"324400ce",null,null);function _(e){for(let t in n)this[t]=n[t]}var p=function(){return l.exports}();export{p as F};