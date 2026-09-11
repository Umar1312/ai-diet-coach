const header=document.querySelector('[data-header]');
const reveals=document.querySelectorAll('.reveal');
const revealObserver=new IntersectionObserver((entries,observer)=>{entries.forEach((entry)=>{if(!entry.isIntersecting)return;entry.target.classList.add('is-visible');observer.unobserve(entry.target);});},{threshold:.14});
reveals.forEach((element)=>revealObserver.observe(element));
window.addEventListener('scroll',()=>{header?.classList.toggle('scrolled',window.scrollY>24);},{passive:true});

const plans=[
  {logged:'Chicken power bowl',loggedMacro:'610 cal',calories:'1,149',protein:'63g',emoji:'🍝',next:'Lentil pasta & chicken',nextMacro:'700 cal',note:'Everything after lunch now fits your remaining calories and protein.'},
  {logged:'Margherita pizza',loggedMacro:'840 cal',calories:'919',protein:'72g',emoji:'🥙',next:'High-protein veggie wrap',nextMacro:'510 cal',note:'Dinner got lighter and more protein-forward — the day still works.'},
  {logged:'Sushi with friends',loggedMacro:'720 cal',calories:'1,039',protein:'68g',emoji:'🍲',next:'Chicken & greens bowl',nextMacro:'580 cal',note:'Your remaining meals were reshaped automatically around lunch.'}
];
let planIndex=0;
const swapButton=document.querySelector('[data-swap]');
const nextRow=document.querySelector('[data-next-row]');
swapButton?.addEventListener('click',()=>{planIndex=(planIndex+1)%plans.length;const plan=plans[planIndex];nextRow?.classList.add('is-changing');window.setTimeout(()=>{document.querySelector('[data-logged-meal]').textContent=plan.logged;document.querySelector('[data-logged-macro]').textContent=plan.loggedMacro;document.querySelector('[data-calories]').textContent=plan.calories;document.querySelector('[data-protein]').textContent=plan.protein;document.querySelector('[data-next-emoji]').textContent=plan.emoji;document.querySelector('[data-next-meal]').textContent=plan.next;document.querySelector('[data-next-macro]').textContent=plan.nextMacro;document.querySelector('[data-demo-note]').textContent=plan.note;nextRow?.classList.remove('is-changing');},260);});
