<!DOCTYPE html>
<html lang='en'><head>
  <meta charset='utf-8'>
<meta name='viewport' content='width=device-width, initial-scale=1'>
<meta name='description' content='According to the Wikipedia the Liskov Substitution Principle (LSP) is defined as:
Subtype Requirement: Let f(x) be a property provable about objects x of type T. Then f(y) should be true for objects y of type S where S is a subtype of T. The basic idea - if you have an object of type T then you can also use objects of its subclasses instead of it.
Or, in other words: the subclass should behave the same way as the base class.'>
<meta name='theme-color' content='#44ccff'>

<meta property='og:title' content='OOP SOLID Principles &#34;L&#34; - Liskov Substitution Principle • vim, git, aws and other three-letter words'>
<meta property='og:description' content='According to the Wikipedia the Liskov Substitution Principle (LSP) is defined as:
Subtype Requirement: Let f(x) be a property provable about objects x of type T. Then f(y) should be true for objects y of type S where S is a subtype of T. The basic idea - if you have an object of type T then you can also use objects of its subclasses instead of it.
Or, in other words: the subclass should behave the same way as the base class.'>
<meta property='og:url' content='https://serebrov.github.io/html/2016-02-18-oop-solid-l-liskov-substitution-principle.md'>
<meta property='og:site_name' content='vim, git, aws and other three-letter words'>
<meta property='og:type' content='article'><meta property='article:section' content='posts'><meta property='article:tag' content='oop'><meta property='article:published_time' content='2016-02-18T00:00:00Z'/><meta property='article:modified_time' content='2016-02-18T00:00:00Z'/><meta name='twitter:card' content='summary'>

<meta name="generator" content="Hugo 0.67.0" />

  <title>OOP SOLID Principles &#34;L&#34; - Liskov Substitution Principle • vim, git, aws and other three-letter words</title>
  <link rel='canonical' href='https://serebrov.github.io/html/2016-02-18-oop-solid-l-liskov-substitution-principle.md'>
  
  
  <link rel='icon' href='/favicon.ico'>
<link rel='stylesheet' href='/assets/css/main.6a060eb7.css'><link rel='stylesheet' href='/css/custom.css'><style>
:root{--color-accent:#44ccff;}
</style>

<script type="application/javascript">
var doNotTrack = false;
if (!doNotTrack) {
	window.ga=window.ga||function(){(ga.q=ga.q||[]).push(arguments)};ga.l=+new Date;
	ga('create', 'UA-58056088-1', 'auto');
	
	ga('send', 'pageview');
}
</script>
<script async src='https://www.google-analytics.com/analytics.js'></script>

  

</head>
<body class='page type-post has-sidebar'>

  <div class='site'><div id='sidebar' class='sidebar'>
  <a class='screen-reader-text' href='#main-menu'>Skip to Main Menu</a>

  <div class='container'><section class='widget widget-about sep-after'>
  <header>
    
    <div class='logo'>
      <a href='/'>
        <img src='/images/logo.jpg'>
      </a>
    </div>
    
    <h2 class='title site-title '>
      <a href='/'>
      vim, git, aws and other three-letter words
      </a>
    </h2>
    <div class='desc'>
    Software Development Notes
    </div>
  </header>

</section>
<section class='widget widget-search sep-after'>
  <header>
    <h4 class='title widget-title'>Search</h4>
  </header>

  <form action='/search' id='search-form' class='search-form'>
    <label>
      <span class='screen-reader-text'>Search</span>
      <input id='search-term' class='search-term' type='search' name='q' placeholder='Search&hellip;'>
    </label></form>

</section>
<section class='widget widget-sidebar_menu sep-after'><nav id='sidebar-menu' class='menu sidebar-menu' aria-label='Sidebar Menu'>
    <div class='container'>
      <ul><li class='item'>
  <a href='/'>Home</a></li><li class='item'>
  <a href='/posts/'>Posts</a></li><li class='item'>
  <a href='/archive/'>Archive</a></li></ul>
    </div>
  </nav>

</section><section class='widget widget-taxonomy_cloud sep-after'>
  <header>
    <h4 class='title widget-title'>Tags</h4>
  </header>

  <div class='container list-container'>
  <ul class='list taxonomy-cloud no-shuffle'><li>
        <a href='/tags/android/' style='font-size:1em'>android</a>
      </li><li>
        <a href='/tags/angularjs/' style='font-size:1.1176470588235294em'>angularjs</a>
      </li><li>
        <a href='/tags/aws/' style='font-size:2em'>aws</a>
      </li><li>
        <a href='/tags/celery/' style='font-size:1em'>celery</a>
      </li><li>
        <a href='/tags/chrome/' style='font-size:1em'>chrome</a>
      </li><li>
        <a href='/tags/cw-logs/' style='font-size:1.0588235294117647em'>cw-logs</a>
      </li><li>
        <a href='/tags/disqus/' style='font-size:1em'>disqus</a>
      </li><li>
        <a href='/tags/docker/' style='font-size:1em'>docker</a>
      </li><li>
        <a href='/tags/drone/' style='font-size:1em'>drone</a>
      </li><li>
        <a href='/tags/dynamodb/' style='font-size:1.1176470588235294em'>dynamodb</a>
      </li><li>
        <a href='/tags/eb/' style='font-size:1.1764705882352942em'>eb</a>
      </li><li>
        <a href='/tags/ejs/' style='font-size:1em'>ejs</a>
      </li><li>
        <a href='/tags/emr/' style='font-size:1.0588235294117647em'>emr</a>
      </li><li>
        <a href='/tags/express.js/' style='font-size:1em'>express.js</a>
      </li><li>
        <a href='/tags/git/' style='font-size:1.8823529411764706em'>git</a>
      </li><li>
        <a href='/tags/hive/' style='font-size:1em'>hive</a>
      </li><li>
        <a href='/tags/jquery/' style='font-size:1.1764705882352942em'>jquery</a>
      </li><li>
        <a href='/tags/js/' style='font-size:1.1176470588235294em'>js</a>
      </li><li>
        <a href='/tags/linux/' style='font-size:1em'>linux</a>
      </li><li>
        <a href='/tags/mongodb/' style='font-size:1em'>mongodb</a>
      </li><li>
        <a href='/tags/mysql/' style='font-size:1.0588235294117647em'>mysql</a>
      </li><li>
        <a href='/tags/node.js/' style='font-size:1.1764705882352942em'>node.js</a>
      </li><li>
        <a href='/tags/npm/' style='font-size:1em'>npm</a>
      </li><li>
        <a href='/tags/oauth/' style='font-size:1em'>oauth</a>
      </li><li>
        <a href='/tags/oop/' style='font-size:1em'>oop</a>
      </li><li>
        <a href='/tags/php/' style='font-size:1.1764705882352942em'>php</a>
      </li><li>
        <a href='/tags/postgresql/' style='font-size:1em'>postgresql</a>
      </li><li>
        <a href='/tags/python/' style='font-size:1.1176470588235294em'>python</a>
      </li><li>
        <a href='/tags/rds/' style='font-size:1em'>rds</a>
      </li><li>
        <a href='/tags/scaleway/' style='font-size:1em'>scaleway</a>
      </li><li>
        <a href='/tags/selenium/' style='font-size:1.3529411764705883em'>selenium</a>
      </li><li>
        <a href='/tags/ssh/' style='font-size:1em'>ssh</a>
      </li><li>
        <a href='/tags/typing/' style='font-size:1em'>typing</a>
      </li><li>
        <a href='/tags/vim/' style='font-size:1em'>vim</a>
      </li><li>
        <a href='/tags/yii/' style='font-size:1.1764705882352942em'>yii</a>
      </li><li>
        <a href='/tags/zeromq/' style='font-size:1em'>zeromq</a>
      </li></ul>
</div>


</section>
</div>

  <div class='sidebar-overlay'></div>
</div><div class='main'><nav id='main-menu' class='menu main-menu' aria-label='Main Menu'>
  <div class='container'>
    <a class='screen-reader-text' href='#content'>Skip to Content</a>

<button id='sidebar-toggler' class='sidebar-toggler' aria-controls='sidebar'>
  <span class='screen-reader-text'>Toggle Sidebar</span>
  <span class='open'><svg class='icon' viewbox='0 0 24 24' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' aria-hidden='true'>
  
  <line x1="3" y1="12" x2="21" y2="12" />
  <line x1="3" y1="6" x2="21" y2="6" />
  <line x1="3" y1="18" x2="21" y2="18" />
  
</svg>
</span>
  <span class='close'><svg class='icon' viewbox='0 0 24 24' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' aria-hidden='true'>
  
  <line x1="18" y1="6" x2="6" y2="18" />
  <line x1="6" y1="6" x2="18" y2="18" />
  
</svg>
</span>
</button>
    <ul><li class='item'>
        <a href='/'>Home</a>
      </li><li class='item'>
        <a href='/'>Home</a>
      </li><li class='item'>
        <a href='/posts/'>Posts</a>
      </li><li class='item'>
        <a href='/archive/'>Archive</a>
      </li></ul>
  </div>
</nav><div class='header-widgets'>
        <div class='container'>
    
    <style>.widget-breadcrumbs li:after{content:'\2f '}</style>
  <section class='widget widget-breadcrumbs sep-after'>
    <nav id='breadcrumbs'>
      <ol><li><a href='/'>Home</a></li><li><a href='/posts/'>Posts</a></li><li><span>OOP SOLID Principles &#34;L&#34; - Liskov Substitution Principle</span></li></ol>
    </nav>
  </section></div>
      </div>

      <header id='header' class='header site-header'>
        <div class='container sep-after'>
          <div class='header-info'><p class='site-title title'>vim, git, aws and other three-letter words</p><p class='desc site-desc'>Software Development Notes</p>
          </div>
        </div>
      </header>

      <main id='content'>


<article lang='en' class='entry'>
  <header class='header entry-header'>
  <div class='container sep-after'>
    <div class='header-info'>
      <h1 class='title'>OOP SOLID Principles &#34;L&#34; - Liskov Substitution Principle</h1>
      

    </div>
    <div class='entry-meta'>
  <span class='posted-on'><svg class='icon' viewbox='0 0 24 24' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' aria-hidden='true'>
  
  <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
  <line x1="16" y1="2" x2="16" y2="6"/>
  <line x1="8" y1="2" x2="8" y2="6"/>
  <line x1="3" y1="10" x2="21" y2="10"/>
  
</svg>
<span class='screen-reader-text'>Posted on </span>
  <time class='entry-date' datetime='2016-02-18T00:00:00Z'>2016, Feb 18</time>
</span>

  
  
<span class='reading-time'><svg class='icon' viewbox='0 0 24 24' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' aria-hidden='true'>
  
  <circle cx="12" cy="12" r="10"/>
  <polyline points="12 6 12 12 15 15"/>
  
</svg>
9 mins read
</span>


  
  
</div>


  </div>
</header>

  
  

  <div class="container entry-content custom">
    <p>According to the <a href="https://en.wikipedia.org/wiki/Liskov_substitution_principle">Wikipedia</a> the Liskov Substitution Principle (LSP) is defined as:</p>
<pre><code>Subtype Requirement:
Let f(x) be a property provable about objects x of type T.
Then f(y) should be true for objects y of type S where S is a subtype of T.
</code></pre><p>The basic idea - if you have an object of type <code>T</code> then you can also use objects of its subclasses instead of it.</p>
<p>Or, in other words: the subclass should behave the same way as the base class. It can add some new features on top of the base class (that&rsquo;s the purpose of inheritance, right?), but it can not break expectations about the base class behavior.</p>
<!-- raw HTML omitted -->
<p>The expectations about the base class can include:</p>
<ul>
<li>input parameters for class methods</li>
<li>returned values of the class methods</li>
<li>exceptions are thrown by the class methods</li>
<li>how method calls change the object state</li>
<li>other expectations about what the object does and how</li>
</ul>
<p>Some of these expectations can be enforced by the programming language, but some of them can only be expressed as the documentation.</p>
<p>This way to follow the LSP it is not only important to follow the coding rules, but also to use common sense and do not use the inheritance to turn the class into something completely different.</p>
<p>Let&rsquo;s see what rules do we need to follow in the code.</p>
<h1 id="methods-signature-requirements">Methods Signature Requirements</h1>
<p>Signature requirements are requirements for input argument types and return type of the class methods.</p>
<p>Let&rsquo;s imagine we have following class hierarchy:</p>
<div class="highlight"><pre style="color:#f8f8f2;background-color:#272822;-moz-tab-size:4;-o-tab-size:4;tab-size:4"><code class="language-text" data-lang="text">   .------------.          .------------.          .-------------.
   | LiveBeing  |          |   Animal   |&lt;|--------|     Cat     |
   |------------|&lt;|--------|------------|          |-------------|
   | + breeze() |          | + eat()    |&lt;|---.    | + mew()     |
   &#39;------------&#39;          &#39;------------&#39;     |    &#39;-------------&#39;
                                              |
                                              |     .------------.
                                              |     |    Dog     |
                                              &#39;-----|------------|
                                                    | + bark()   |
                                                    &#39;------------&#39;
</code></pre></div><p>Here the <code>LiveBeing</code> is the base class which is inherited by <code>Animal</code> which in turn is inherited by <code>Cat</code> and <code>Dog</code>.</p>
<p>I will use this hierarchy to explain the signature rules.</p>
<h2 id="covariance-parent---child----of-return-types-in-the-subtype">Covariance (Parent -&gt; Child -&gt; &hellip;) of return types in the subtype</h2>
<p>This rule means that the child class can override a method to return a more specific type (<code>Cat</code> instead of <code>Animal</code>).</p>
<p>Of course, it can return the same type, but it can not return more generic type (like <code>LiveBeing</code> instead of <code>Animal</code>) and it can not return a completely different type (<code>House</code> instead of <code>Animal</code>).</p>
<p>This rule is easy to understand and it feels natural.
Here is an example in pseudo-code:</p>
<div class="highlight"><pre style="color:#f8f8f2;background-color:#272822;-moz-tab-size:4;-o-tab-size:4;tab-size:4"><code class="language-python" data-lang="python">
<span style="color:#66d9ef">class</span> <span style="color:#a6e22e">Owner</span>
  Animal findPet()
      <span style="color:#66d9ef">return</span> new Animal()

<span style="color:#66d9ef">class</span> <span style="color:#a6e22e">CatOwner</span> extends Owner
  Cat findPet()
      <span style="color:#75715e"># Covariance - subclass returns more specific type</span>
      <span style="color:#66d9ef">return</span> new Cat()

<span style="color:#66d9ef">class</span> <span style="color:#a6e22e">BadOwner</span> extends Owner
  LiveBeing findPet()
      <span style="color:#75715e"># Contravariance - breaks the rule and returns more generic type</span>
      <span style="color:#66d9ef">return</span> new LiveBeing()

function doAction(Owner owner)
    <span style="color:#75715e"># OK for Owner, we can put an Animal object into the `animal` variable.</span>
    <span style="color:#75715e"># OK for CatOwner, we can put a Cat object into the `animal` variable.</span>
    <span style="color:#75715e"># Problem for a BadOwner object, a LiveBeing object can not use be used</span>
    <span style="color:#75715e"># the same way as Animal object.</span>
    Animal animal <span style="color:#f92672">=</span> owner<span style="color:#f92672">-&gt;</span>findPet();
    amimal<span style="color:#f92672">-&gt;</span>eat();
</code></pre></div><p>The <code>doAction</code> function demonstrates a possible use case.
It is OK if <code>owner</code> is a <code>CatOwner</code>, because both <code>Animal</code> and <code>Cat</code> should behave the same.</p>
<p>But the <code>BadOwner</code> returns a <code>LiveBeing</code> and it is a problem. There is no guarantee that <code>LiveBeing</code> object behaves the same as <code>Animal</code>.</p>
<p>For example, if we call <code>animal-&gt;eat()</code> this will not work for the <code>LiveBeing</code> (it doesn&rsquo;t have such a method).</p>
<h2 id="contravariance-child---parent----of-method-arguments-in-the-subtype">Contravariance (Child -&gt; Parent -&gt; &hellip;) of method arguments in the subtype</h2>
<p>This means that a child class can override the method to accept a more generic argument type than the method in the base class (like accept the <code>LiveBeing</code> instead of <code>Animal</code>).</p>
<div class="highlight"><pre style="color:#f8f8f2;background-color:#272822;-moz-tab-size:4;-o-tab-size:4;tab-size:4"><code class="language-python" data-lang="python"><span style="color:#66d9ef">class</span> <span style="color:#a6e22e">Owner</span>
  void feed(Animal animal)
    <span style="color:#f92672">...</span>

<span style="color:#66d9ef">class</span> <span style="color:#a6e22e">GoodOwner</span> extends Owner
  <span style="color:#75715e"># Contravariance - subclass accepts more generic type</span>
  void feed(LiveBeing being)
    <span style="color:#f92672">...</span>

<span style="color:#66d9ef">class</span> <span style="color:#a6e22e">BadCatOwner</span> extends Owner
  void feed(Cat cat)
    <span style="color:#f92672">...</span>

function doAction(Owner owner)
  owner<span style="color:#f92672">-&gt;</span>feed(new Dog) <span style="color:#75715e"># OK for Owner, he accepts any Animal, including the Dog</span>
                       <span style="color:#75715e"># OK for GoodOwner, he accepts any LiveBeing, including the Dog</span>
                       <span style="color:#75715e"># Problem for CatOwner, he doesn&#39;t expect the Dog</span>
</code></pre></div><p>In practice, it may feel tempting to break this rule and define the class like <code>BadCatOwner</code> above.</p>
<p>But, as we can see, the <code>BadCatOwner</code> breaks LSP and we can not use it in the same case where we can use the <code>Owner</code> object.</p>
<p>Note that although using the more generic type in the subclass is OK in terms of method signature, it may be problematic logically:</p>
<div class="highlight"><pre style="color:#f8f8f2;background-color:#272822;-moz-tab-size:4;-o-tab-size:4;tab-size:4"><code class="language-python" data-lang="python"><span style="color:#66d9ef">class</span> <span style="color:#a6e22e">Owner</span>
  void feed(Animal animal)
    animal<span style="color:#f92672">-&gt;</span>eat(this<span style="color:#f92672">-&gt;</span>findFood());

<span style="color:#66d9ef">class</span> <span style="color:#a6e22e">GoodOwner</span> extends Owner
  void feed(LiveBeing being)
    <span style="color:#75715e"># Problem: LiveBeing doesn&#39;t have the `eat` method</span>
    being<span style="color:#f92672">-&gt;</span>eat(this<span style="color:#f92672">-&gt;</span>findFood());

</code></pre></div><p>There is a problem here - the <code>GoodOnwer::feed</code> can not call the <code>being-&gt;eat()</code> method because <code>LiveBeing</code> doesn&rsquo;t have the <code>eat</code> method.</p>
<p>And this way, <code>GoodOwner</code> also can not just forward the execution to the parent method with something like <code>parent::feed(being)</code>.</p>
<p>By the way, if the method doesn&rsquo;t use parent implementation, it may <a href="http://stackoverflow.com/q/35070912/4612064">indicate the LSP violation</a> - potentially we can have a different behavior for this subtype than in the parent class.</p>
<h2 id="exceptions-should-be-same-or-subtypes-of-the-base-method-exceptions">Exceptions should be same or subtypes of the base method exceptions</h2>
<p>No new exceptions should be thrown by methods of the subtype, except where those exceptions are themselves subtypes of exceptions thrown by the methods of the parent type.</p>
<div class="highlight"><pre style="color:#f8f8f2;background-color:#272822;-moz-tab-size:4;-o-tab-size:4;tab-size:4"><code class="language-python" data-lang="python"><span style="color:#66d9ef">class</span> <span style="color:#a6e22e">BadFoodException</span>

<span style="color:#66d9ef">class</span> <span style="color:#a6e22e">BadCatFoodException</span> extends BadFoodException

<span style="color:#66d9ef">class</span> <span style="color:#a6e22e">LowQualityFoodException</span>


<span style="color:#66d9ef">class</span> <span style="color:#a6e22e">Owner</span>
  void feed(Animal animal, Food food)
    <span style="color:#66d9ef">if</span> (<span style="color:#f92672">not</span> this<span style="color:#f92672">-&gt;</span>isGoodFood(food))
      throw BadFoodException()
    <span style="color:#f92672">...</span>

<span style="color:#66d9ef">class</span> <span style="color:#a6e22e">BadOwner</span> extends Owner
  void feed(Animal animal, Food food)
    <span style="color:#66d9ef">if</span> (<span style="color:#f92672">not</span> this<span style="color:#f92672">-&gt;</span>isHighQualityFood(food))
      throw LowQualityFoodException()
    <span style="color:#f92672">...</span>

function doAction(Owner owner)
  <span style="color:#66d9ef">try</span>
    owner<span style="color:#f92672">-&gt;</span>feed(new Dog, new SomeFood)
  catch (BadFoodException error)
    <span style="color:#75715e"># OK for Owner, it can raise BadFoodException</span>
    <span style="color:#75715e"># OK for CatOwner, it can raise BadCatFoodException (subclass of BadFoodException)</span>
    <span style="color:#75715e"># Problem for BadOwner, it can raise LowQualityFoodException and it will not be</span>
    <span style="color:#75715e"># caught here</span>
    <span style="color:#f92672">...</span>

</code></pre></div><p>If we don&rsquo;t follow the rule about exception types, the client code written for the base class <code>Owner</code> will fail for the subclass <code>BadOwner</code> and this way we violate the <code>LSP</code>.</p>
<h1 id="inheritance-requirements">Inheritance requirements</h1>
<p>These requirements describe additional rules for inherited methods related to the <a href="https://en.wikipedia.org/wiki/Design_by_contract">Design by contract</a> concept. It defines the &ldquo;contract&rdquo; for each method which includes preconditions, postconditions and invariants:</p>
<ul>
<li><a href="https://en.wikipedia.org/wiki/Precondition">Precondition</a> is a condition or predicate that must always be true just prior to the execution of some section of code.</li>
<li><a href="https://en.wikipedia.org/wiki/Postcondition">Postcondition</a> is a condition or predicate that must always be true just after the execution of some section of code</li>
<li><a href="https://en.wikipedia.org/wiki/Invariant_(computer_science)">Invariant</a> is a condition that can be relied upon to be true during execution of a program, or during some portion of it.  For example, a loop invariant is a condition that is true at the beginning and end of every execution of a loop.</li>
</ul>
<h2 id="preconditions-cannot-be-strengthened-in-a-subtype">Preconditions cannot be strengthened in a subtype</h2>
<p>In most cases preconditions are expectations about method input arguments, also an object&rsquo;s internal state can be a part of the precondition.</p>
<p>This is a more generic rule of the contravariance rule for method arguments. The contravariance rule says that subclass can accept more generic argument type (<code>LiveBeing</code> instead of <code>Animal</code>), this is a weaker precondition (subclass accepts a wider range of arguments).</p>
<p>The same logic applies not only to the types of arguments but to the other kind of expectations as well, such as a range of the integer argument:</p>
<div class="highlight"><pre style="color:#f8f8f2;background-color:#272822;-moz-tab-size:4;-o-tab-size:4;tab-size:4"><code class="language-python" data-lang="python"><span style="color:#66d9ef">class</span> <span style="color:#a6e22e">The24Hours</span>
  void setHour(int hour)
    <span style="color:#75715e"># hour should be between 0 and 23</span>
    <span style="color:#66d9ef">assert</span> (<span style="color:#ae81ff">0</span> <span style="color:#f92672">&lt;=</span> hour <span style="color:#f92672">and</span> hour <span style="color:#f92672">&lt;=</span><span style="color:#ae81ff">23</span>)
    <span style="color:#f92672">...</span>

<span style="color:#66d9ef">class</span> <span style="color:#a6e22e">TheDay</span> extends The24Hours
  void setHour (int hour)
    <span style="color:#75715e"># breaks the rule and strengthens the precondition</span>
    <span style="color:#75715e"># day hour should be between 8 and 16</span>
    <span style="color:#66d9ef">assert</span> (<span style="color:#ae81ff">8</span> <span style="color:#f92672">&lt;=</span> hour <span style="color:#f92672">and</span> hour <span style="color:#f92672">&lt;=</span> <span style="color:#ae81ff">16</span>)
   <span style="color:#f92672">...</span>

function doAction(The24Hours hours)
  hours<span style="color:#f92672">-&gt;</span>setHour(<span style="color:#ae81ff">3</span>); <span style="color:#75715e"># OK for `The24Hours` object</span>
                     <span style="color:#75715e"># Problem for `TheDay` - it will raise an error</span>
</code></pre></div><p>So the stronger precondition in the child class broke the client code which worked for the parent class.</p>
<p>At the same time, if we make the precondition weaker (or even remove it), the client code will work the same way as for parent class.</p>
<h2 id="postconditions-cannot-be-weakened-in-a-subtype">Postconditions cannot be weakened in a subtype</h2>
<p>Postconditions are usually expectations related to the method return value.</p>
<p>Again, this the more generic rule similar to the covariance rule (method can return <code>Cat</code> instead of <code>Animal</code>), the postcondition is strengthened.</p>
<p>An example of postcondition rule violation:</p>
<div class="highlight"><pre style="color:#f8f8f2;background-color:#272822;-moz-tab-size:4;-o-tab-size:4;tab-size:4"><code class="language-python" data-lang="python"><span style="color:#66d9ef">class</span> <span style="color:#a6e22e">The24Hours</span>
  number setHour(number hour)
    <span style="color:#f92672">...</span>
    <span style="color:#66d9ef">assert</span> (this<span style="color:#f92672">.</span>hour <span style="color:#f92672">is</span> integer)
    <span style="color:#66d9ef">return</span> this<span style="color:#f92672">.</span>hour

<span style="color:#66d9ef">class</span> <span style="color:#a6e22e">TheTime</span> extends The24Hours
  number setHour(number hour, number hourFraction)
    this<span style="color:#f92672">.</span>hour <span style="color:#f92672">=</span> hour <span style="color:#f92672">+</span> hourFraction <span style="color:#f92672">/</span> <span style="color:#ae81ff">100</span>
    <span style="color:#75715e"># the postcondition is weaker (float is a wider area than integer)</span>
    <span style="color:#66d9ef">assert</span> (this<span style="color:#f92672">.</span>hour <span style="color:#f92672">is</span> float)
    <span style="color:#66d9ef">return</span> this<span style="color:#f92672">.</span>hour

function doAction(The24Hours hours)
  int result <span style="color:#f92672">=</span> hours<span style="color:#f92672">-&gt;</span>setHour(<span style="color:#ae81ff">3</span>); <span style="color:#75715e"># OK for The24Hours</span>
                                  <span style="color:#75715e"># Problem for TheTime, it returns float</span>
</code></pre></div><p>So again, due to <code>LSP</code> violation, we can not use the child class instead of the parent.</p>
<h2 id="invariants-of-the-parent-type-must-be-preserved-in-a-subtype">Invariants of the parent type must be preserved in a subtype</h2>
<p>Invariant is something that is not changed during the method execution. It can be the whole or part of the object internal state:</p>
<div class="highlight"><pre style="color:#f8f8f2;background-color:#272822;-moz-tab-size:4;-o-tab-size:4;tab-size:4"><code class="language-python" data-lang="python"><span style="color:#66d9ef">class</span> <span style="color:#a6e22e">The24Hours</span>
  <span style="color:#75715e"># invariant: this.hour is not changed</span>
  number getHour()
    <span style="color:#66d9ef">return</span> this<span style="color:#f92672">.</span>hour

<span style="color:#66d9ef">class</span> <span style="color:#a6e22e">TheCounter</span> extends The24Hours
  <span style="color:#75715e"># invariant violation: this.hour is changed</span>
  number getHour()
    result <span style="color:#f92672">=</span> this<span style="color:#f92672">.</span>hour
    this<span style="color:#f92672">.</span>hour <span style="color:#f92672">+=</span> <span style="color:#ae81ff">1</span>
    <span style="color:#66d9ef">return</span> result

function doAction(The24Hours hours)
  <span style="color:#66d9ef">if</span> (hours<span style="color:#f92672">-&gt;</span>getHour() <span style="color:#f92672">&lt;=</span> <span style="color:#ae81ff">12</span>)
     <span style="color:#75715e"># OK for The24Hours</span>
     <span style="color:#75715e"># Problem for TheTime, now getHour() can return value &gt; 12</span>
     <span style="color:#66d9ef">print</span> <span style="color:#e6db74">&#39;First half of the day&#39;</span>, hours<span style="color:#f92672">-&gt;</span>getHour()
</code></pre></div><h2 id="history-constraint-the-history-rule">History constraint (the &ldquo;history rule&rdquo;)</h2>
<p>The subtypes should not introduce new methods that will allow modifying the object state in a way that is not possible for the parent class.</p>
<p>The internal object state should be modifiable only through their methods (encapsulation) and the client code can have some expectations as of the possible ways to modify the internal state.</p>
<p>For example:</p>
<div class="highlight"><pre style="color:#f8f8f2;background-color:#272822;-moz-tab-size:4;-o-tab-size:4;tab-size:4"><code class="language-python" data-lang="python"><span style="color:#66d9ef">class</span> <span style="color:#a6e22e">Time</span>
  <span style="color:#75715e"># it is immutable, once time is set, there is no way to change it</span>
  constructor(int hour, int minute)
  getTime()

<span style="color:#66d9ef">class</span> <span style="color:#a6e22e">FlexibleTime</span> extends Time
  <span style="color:#75715e"># violates the &#34;history&#34; rule</span>
  <span style="color:#75715e"># it allows changing the object state</span>
  <span style="color:#75715e"># but the clients who use Time can be broken due to this</span>
  setTime(int hour, int minute)

doAction(Time time)
  <span style="color:#66d9ef">print</span> <span style="color:#e6db74">&#39;Now it is: &#39;</span>, time<span style="color:#f92672">-&gt;</span>getTime()
  doOtherAction(time)
  <span style="color:#75715e"># OK for Time, it can not be changed, so value is the same</span>
  <span style="color:#75715e"># Problem for FlexibleTime, the `doOtherAction` could change it</span>
  <span style="color:#66d9ef">print</span> <span style="color:#e6db74">&#39;Now it is still: &#39;</span>, time<span style="color:#f92672">-&gt;</span>getTime()

</code></pre></div><h1 id="links">Links</h1>
<p><a href="https://en.wikipedia.org/wiki/Liskov_substitution_principle">Wikipedia:Liskov substitution principle</a></p>
<p><a href="http://www.engr.mun.ca/~theo/Courses/sd/5895-downloads/sd-principles-3.ppt.pdf">Agile Design Principles: The Liskov Substitution Principle</a></p>
<p><a href="https://en.wikipedia.org/wiki/Covariance_and_contravariance_(computer_science)#Inheritance_in_object-oriented_languages">Wikipedia: Covariance and contravariance</a></p>
 <a href="https://stackexchange.com/users/261528">
<img src="https://stackexchange.com/users/flair/261528.png?theme=clean" width="208" height="58" alt="profile for Boris Serebrov on Stack Exchange, a network of free, community-driven Q&amp;A sites" title="profile for Boris Serebrov on Stack Exchange, a network of free, community-driven Q&amp;A sites">
</a>

</div>
<div class="popup">
    <div class="close">close</div>
    <div class="download">
        <a href="" target="_blank">Download (<span class="name"></span>)</a>
    </div>
    <div class="popup-content"></div>
</div>

  
<footer class='entry-footer'>
  <div class='container sep-before'><div class='tags'><svg class='icon' viewbox='0 0 24 24' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' aria-hidden='true'>
  
  <path d="M20.59,13.41l-7.17,7.17a2,2,0,0,1-2.83,0L2,12V2H12l8.59,8.59A2,2,0,0,1,20.59,13.41Z"/>
  <line x1="7" y1="7" x2="7" y2="7"/>
  
</svg>
<span class='screen-reader-text'>Tags: </span><a class='tag' href='/tags/oop/'>oop</a></div>

  </div>
</footer>


</article>

<nav class='entry-nav'>
  <div class='container'><div class='prev-entry sep-before'>
      <a href='/html/2015-09-22-aws-postgresql-max-connections.html'>
        <span aria-hidden='true'><svg class='icon' viewbox='0 0 24 24' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' aria-hidden='true'>
  
  <line x1="20" y1="12" x2="4" y2="12"/>
  <polyline points="10 18 4 12 10 6"/>
  
</svg>
 Previous</span>
        <span class='screen-reader-text'>Previous post: </span>AWS PostgreSQL RDS - remaining connection slots are reserved error</a>
    </div><div class='next-entry sep-before'>
      <a href='/html/2016-06-10-scaleway-docker-deployment.html'>
        <span class='screen-reader-text'>Next post: </span>Setup Automatic Deployment, Updates and Backups of Multiple Web Applications with Docker on the Scaleway Server<span aria-hidden='true'>Next <svg class='icon' viewbox='0 0 24 24' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' aria-hidden='true'>
  
  <line x1="4" y1="12" x2="20" y2="12"/>
  <polyline points="14 6 20 12 14 18"/>
  
</svg>
</span>
      </a>
    </div></div>
</nav>


<section id='comments' class='comments'>
  <div class='container sep-before'>
    <div class='comments-area'><div id="disqus_thread"></div>
<script>
    var relLink = "\/html\/2016-02-18-oop-solid-l-liskov-substitution-principle.md";
    relLink = relLink.replace("\/", "/");
    if (relLink.endsWith("/")) {
        relLink = relLink.substr(0, relLink.length - 1);
    }
    var disqus_config = function () {
        this.page.url = "http://serebrov.github.io" + relLink; 
        console.log('set page url', this.page.url);
        
    };
    (function () {
        
        var d = document,
            s = d.createElement("script");
        s.src = "https://serebrov.disqus.com/embed.js";
        s.setAttribute("data-timestamp", +new Date());
        (d.head || d.body).appendChild(s);
    })();
</script>
<noscript
    >Please enable JavaScript to view the
    <a href="https://disqus.com/?ref_noscript"
        >comments powered by Disqus.</a
    ></noscript
>
</div>
  </div>
</section>

      </main>

      <footer id='footer' class='footer'>
        <div class='container sep-before'><section class='widget widget-social_menu sep-after'><nav aria-label='Social Menu'>
    <ul><li>
        <a href='https://github.com/serebrov' target='_blank' rel='noopener'>
          <span class='screen-reader-text'>Open Github account in new tab</span><svg class='icon' viewbox='0 0 24 24' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' aria-hidden='true'>
  
  <path d="M9 19c-5 1.5-5-2.5-7-3m14 6v-3.87a3.37 3.37 0 0 0-.94-2.61c3.14-.35 6.44-1.54 6.44-7A5.44 5.44 0 0 0 20 4.77 5.07 5.07 0 0 0 19.91 1S18.73.65 16 2.48a13.38 13.38 0 0 0-7 0C6.27.65 5.09 1 5.09 1A5.07 5.07 0 0 0 5 4.77a5.44 5.44 0 0 0-1.5 3.78c0 5.42 3.3 6.61 6.44 7A3.37 3.37 0 0 0 9 18.13V22"/>
  
</svg>
</a>
      </li><li>
        <a href='mailto:serebrov@gmail.com' target='_blank' rel='noopener'>
          <span class='screen-reader-text'>Contact via Email</span><svg class='icon' viewbox='0 0 24 24' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' aria-hidden='true'>
  
  <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
  <polyline points="22,6 12,13 2,6"/>
  
</svg>
</a>
      </li></ul>
  </nav>
</section><div class='copyright'>
  <p> &copy; 2020 Boris Serebrov </p>
</div>

        </div>
      </footer>

    </div>
  </div><script>window.__assets_js_src="/assets/js/"</script>

<script src='https://serebrov.github.io/assets/js/main.67d669ac.js'></script><script src='/js/jquery.min.js'></script><script src='/js/custom.js'></script>


</body>

</html>






















