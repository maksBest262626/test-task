<?php

namespace App\Controller;

use App\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Psr\Container\ContainerInterface;
use Psr\Log\LoggerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController as SymfonyAbstractController;
use Symfony\Component\HttpFoundation\RedirectResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Symfony\Component\Security\Core\User\UserInterface;

abstract class AbstractController extends SymfonyAbstractController
{
    private array $_context = [];

    public function __construct(
        private readonly EntityManagerInterface $entityManager,
        private readonly LoggerInterface $logger,
    ) {}

    protected function getContext(): array
    {
        return $this->_context;
    }

    public function getContainer(): ContainerInterface
    {
        return $this->container;
    }

    public function getEntityManager(): EntityManagerInterface
    {
        return $this->entityManager;
    }

    public function getLogger(): LoggerInterface
    {
        return $this->logger;
    }

    protected function getRequest(): Request
    {
        try {
            return $this->getContainer()->get('request_stack')->getCurrentRequest();
        } catch (\Throwable $e) {
            $this->logger->error(sprintf("getRequest: %s", $e->getMessage()));
            $this->httpException(Response::HTTP_BAD_REQUEST, 'Request error.');
        }
    }

    protected function getCurrentRouteName(): ?string
    {
        return $this->getRequest()->get('_route');
    }

    protected function addContext(array $context = []): void
    {
        $this->_context = array_merge($this->_context, $context);
    }

    public function addFlash(string $type, mixed $message): void
    {
        parent::addFlash($type, $message);
    }

    /** @throws HttpException */
    protected function httpException($code, $message = ''): User|UserInterface|null
    {
        throw new HttpException($code, $message);
    }

    public function redirectToRoute(string $route, array $parameters = [], int $status = 302): RedirectResponse
    {
        return parent::redirect($this->generateUrl($route, $parameters), $status);
    }

    /** @return User|UserInterface|null */
    public function getUser(): User|UserInterface|null
    {
        return parent::getUser();
    }
}
