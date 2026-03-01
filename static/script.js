/**
 * DevSecOps Dashboard — Interactive Script
 * Simulates pipeline status animation on page load.
 */

document.addEventListener("DOMContentLoaded", () => {
    // Animate pipeline statuses sequentially
    simulatePipelineRun();

    // Intersection Observer for scroll animations
    setupScrollAnimations();
});


/**
 * Simulate pipeline stages completing one by one.
 */
function simulatePipelineRun() {
    const stages = [
        { id: "status-1", delay: 1500, status: "✅ Passed", className: "status-pass" },
        { id: "status-2", delay: 3000, status: "✅ Passed", className: "status-pass" },
        { id: "status-3", delay: 4500, status: "✅ Passed", className: "status-pass" },
        { id: "status-4", delay: 6500, status: "✅ Passed", className: "status-pass" },
        { id: "status-5", delay: 8500, status: "🚀 Deployed", className: "status-pass" },
    ];

    // Reset all to "pending" first
    stages.forEach((stage) => {
        const el = document.getElementById(stage.id);
        if (el) {
            el.textContent = "⏳ Pending";
            el.className = "status-badge status-pending";
        }
    });

    // Set stage 1 to "running" immediately
    const firstEl = document.getElementById(stages[0].id);
    if (firstEl) {
        firstEl.textContent = "🔄 Running";
        firstEl.className = "status-badge status-running";
    }

    stages.forEach((stage, index) => {
        setTimeout(() => {
            const el = document.getElementById(stage.id);
            if (el) {
                el.textContent = stage.status;
                el.className = `status-badge ${stage.className}`;
            }

            // Set next stage to "running"
            if (index + 1 < stages.length) {
                const nextEl = document.getElementById(stages[index + 1].id);
                if (nextEl) {
                    nextEl.textContent = "🔄 Running";
                    nextEl.className = "status-badge status-running";
                }
            }
        }, stage.delay);
    });
}


/**
 * Apply fade-in animation when elements enter the viewport.
 */
function setupScrollAnimations() {
    const observer = new IntersectionObserver(
        (entries) => {
            entries.forEach((entry) => {
                if (entry.isIntersecting) {
                    entry.target.style.opacity = "1";
                    entry.target.style.transform = "translateY(0)";
                }
            });
        },
        { threshold: 0.1 }
    );

    document.querySelectorAll(".tool-card, .pipeline-step").forEach((el) => {
        el.style.opacity = "0";
        el.style.transform = "translateY(30px)";
        el.style.transition = "opacity 0.6s ease, transform 0.6s ease";
        observer.observe(el);
    });
}
